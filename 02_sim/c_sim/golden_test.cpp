#include <iostream>
#include <vector>
#include <cmath>
#include <algorithm>
#include <chrono>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

// =========================================================================================
// HÀM ĐÁNH GIÁ CHẤT LƯỢNG 
// =========================================================================================
void compute_metrics(const std::vector<uint8_t>& original, const std::vector<uint8_t>& filtered, int width, int height, double& mse, double& mae) {
    double sum_sq = 0, sum_abs = 0;
    int count = width * height;
    for (int i = 0; i < count; i++) {
        double diff = (double)original[i] - (double)filtered[i];
        sum_sq += diff * diff;
        sum_abs += std::abs(diff);
    }
    mse = sum_sq / count;
    mae = sum_abs / count;
}

// =========================================================================================
// KHỐI 1A: SWITCHING MEDIAN CHUẨN LÝ THUYẾT (Floating-point / Exact logic)
// =========================================================================================
void run_standard_switching_median(const std::vector<uint8_t>& input, std::vector<uint8_t>& output, uint8_t threshold, int width, int height) {
    output = input;
    for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
            int window[9];
            int idx = 0;
            for (int ky = -1; ky <= 1; ky++) {
                for (int kx = -1; kx <= 1; kx++) {
                    window[idx++] = input[(y + ky) * width + (x + kx)];
                }
            }
            std::sort(window, window + 9);
            int y_med = window[4];
            
            int center_pixel = input[y * width + x];
            if (std::abs(center_pixel - y_med) >= threshold) {
                output[y * width + x] = y_med;
            } else {
                output[y * width + x] = center_pixel;
            }
        }
    }
}

// =========================================================================================
// KHỐI 1B: BILATERAL FILTER CHUẨN LÝ THUYẾT (Dùng hàm exp, dấu phẩy động)
// Tham số chuẩn: Cửa sổ 3x3, sigma_s = 0.5, sigma_r = 15
// =========================================================================================
void run_standard_bilateral_filter(const std::vector<uint8_t>& input, std::vector<uint8_t>& output, int width, int height, double sigma_s, double sigma_r) {
    output = input; 
    double two_sigma_s_sq = 2.0 * sigma_s * sigma_s;
    double two_sigma_r_sq = 2.0 * sigma_r * sigma_r;

    for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
            double num = 0.0;
            double den = 0.0;
            double center_val = input[y * width + x];

            for (int ky = -1; ky <= 1; ky++) {
                for (int kx = -1; kx <= 1; kx++) {
                    double neighbor_val = input[(y + ky) * width + (x + kx)];
                    double spatial_dist_sq = kx * kx + ky * ky;
                    double range_dist_sq = (neighbor_val - center_val) * (neighbor_val - center_val);

                    // Phép tính hàm mũ (exp) tốn kém tài nguyên nhất
                    double w_s = std::exp(-spatial_dist_sq / two_sigma_s_sq);
                    double w_r = std::exp(-range_dist_sq / two_sigma_r_sq);
                    double w = w_s * w_r;

                    num += neighbor_val * w;
                    den += w;
                }
            }
            output[y * width + x] = std::min(255.0, std::max(0.0, std::round(num / den)));
        }
    }
}

// =========================================================================================
// HÀM SẮP XẾP 3 PHẦN TỬ (Mô phỏng Mạng Comparator Phần cứng)
// =========================================================================================
void sort3(int a, int b, int c, int& min_val, int& med_val, int& max_val) {
    int arr[3] = {a, b, c};
    std::sort(arr, arr + 3); 
    min_val = arr[0];
    med_val = arr[1];
    max_val = arr[2];
}

// =========================================================================================
// KHỐI GIA TỐC 1: SWITCHING MEDIAN FILTER (RTL Model)
// =========================================================================================
void run_rtl_switching_median(const std::vector<uint8_t>& input, std::vector<uint8_t>& output, uint8_t threshold, int width, int height) {
    output = input; // Copy viền ảnh (Bypass border pixels)
    for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) { 
            int p00 = input[(y - 1) * width + (x - 1)];
            int p01 = input[(y - 1) * width + (x + 0)];
            int p02 = input[(y - 1) * width + (x + 1)];
            int p10 = input[(y + 0) * width + (x - 1)];
            int p11 = input[(y + 0) * width + (x + 0)]; 
            int p12 = input[(y + 0) * width + (x + 1)];
            int p20 = input[(y + 1) * width + (x - 1)];
            int p21 = input[(y + 1) * width + (x + 0)];
            int p22 = input[(y + 1) * width + (x + 1)];

            // Tính toán trung vị (Median Calculation)
            int min_r1, med_r1, max_r1, min_r2, med_r2, max_r2, min_r3, med_r3, max_r3;
            sort3(p00, p01, p02, min_r1, med_r1, max_r1);
            sort3(p10, p11, p12, min_r2, med_r2, max_r2);
            sort3(p20, p21, p22, min_r3, med_r3, max_r3);

            int dummy_min, dummy_med, dummy_max, max_of_mins, med_of_meds, min_of_maxs;
            sort3(min_r1, min_r2, min_r3, dummy_min, dummy_med, max_of_mins);
            sort3(med_r1, med_r2, med_r3, dummy_min, med_of_meds, dummy_max);
            sort3(max_r1, max_r2, max_r3, min_of_maxs, dummy_med, dummy_max);

            int final_median;
            sort3(max_of_mins, med_of_meds, min_of_maxs, dummy_min, final_median, dummy_max);

            // Phát hiện nhiễu (Noise Detection)
            int center_sl   = p11 * 2; 
            int vert_dev    = std::min(255, std::abs((p21 + p01) - center_sl));
            int hor_dev     = std::min(255, std::abs((p12 + p10) - center_sl));
            int crossl_dev  = std::min(255, std::abs((p22 + p00) - center_sl));
            int crossr_dev  = std::min(255, std::abs((p20 + p02) - center_sl));

            int min_vh  = std::min(vert_dev, hor_dev);
            int min_lr  = std::min(crossl_dev, crossr_dev);
            int min_all = std::min(min_vh, min_lr);

            // Mux đầu ra
            if (min_all >= threshold) {
                output[y * width + x] = final_median; 
            } else {
                output[y * width + x] = p11;          
            }
        }
    }
}

// =========================================================================================
// HÀM LUT: RANGE KERNEL APPROXIMATION (σ_r = 15)
// =========================================================================================
int get_AWr(int diff) {
    if (diff < 4)  return 64;
    if (diff < 7)  return 60;
    if (diff < 10) return 56;
    if (diff < 13) return 48;
    if (diff < 17) return 40;
    if (diff < 20) return 32;
    if (diff < 22) return 24;
    if (diff < 24) return 20;
    if (diff < 27) return 16;
    if (diff < 29) return 12;
    if (diff < 33) return 8;
    if (diff < 38) return 4;
    if (diff < 40) return 2;
    if (diff < 44) return 1;
    return 0;
}

// =========================================================================================
// KHỐI GIA TỐC 2: APPROXIMATE BILATERAL FILTER (RTL Model) 
// =========================================================================================
void run_rtl_bilateral_filter(const std::vector<uint8_t>& input, std::vector<uint8_t>& output, int width, int height) {
    output = input; // Copy viền ảnh
    for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
            int p[9];
            p[0] = input[(y - 1) * width + (x - 1)]; p[1] = input[(y - 1) * width + (x + 0)]; p[2] = input[(y - 1) * width + (x + 1)]; 
            p[3] = input[(y + 0) * width + (x - 1)]; p[4] = input[(y + 0) * width + (x + 0)]; p[5] = input[(y + 0) * width + (x + 1)]; 
            p[6] = input[(y + 1) * width + (x - 1)]; p[7] = input[(y + 1) * width + (x + 0)]; p[8] = input[(y + 1) * width + (x + 1)]; 

            int abs_diff[9];
            for (int i = 0; i < 9; i++) abs_diff[i] = std::abs(p[i] - p[4]); 

            int w_total[9];
            for (int i = 0; i < 9; i++) {
                int awr = get_AWr(abs_diff[i]);
                if (i == 4) w_total[i] = awr << 6;
                else if (i == 1 || i == 3 || i == 5 || i == 7) w_total[i] = awr << 5;
                else w_total[i] = awr << 4;
            }

            long long numerator = 0;
            int denominator = 0;
            for (int i = 0; i < 9; i++) {
                numerator += p[i] * w_total[i]; 
                denominator += w_total[i];      
            }

            if (denominator == 0) denominator = 1; 
            output[y * width + x] = std::min(255LL, numerator / denominator);
        }
    }
}

// =========================================================================================
// CHƯƠNG TRÌNH CHÍNH
// =========================================================================================
int main() {
    int width, height, channels;
    const char* input_image_path = "input_image.png"; 

    unsigned char* img_data = stbi_load(input_image_path, &width, &height, &channels, 1);
    if (!img_data) {
        std::cerr << "[ERROR] Không thể tải ảnh: " << input_image_path << "\n";
        return -1;
    }

    std::cout << "[INFO] Đã tải ảnh: " << width << "x" << height << "\n";
    int total_pixels = width * height;

    std::vector<uint8_t> original(img_data, img_data + total_pixels);
    std::vector<uint8_t> noisy = original;
    stbi_image_free(img_data); 

    int noise_pixels = total_pixels * 0.05; 
    for (int i = 0; i < noise_pixels; i++) {
        int target = rand() % total_pixels;
        noisy[target] = (i % 2 == 0) ? 255 : 0; 
    }

    std::vector<uint8_t> std_median_out(total_pixels, 0); 
    std::vector<uint8_t> std_final_out(total_pixels, 0);
    std::vector<uint8_t> rtl_median_out(total_pixels, 0); 
    std::vector<uint8_t> rtl_final_out(total_pixels, 0);

    uint8_t threshold = 20;

    // 1. Chạy Pipeline Lý Thuyết (Exact / Standard)
    auto start_std = std::chrono::high_resolution_clock::now();
    run_standard_switching_median(noisy, std_median_out, threshold, width, height);
    run_standard_bilateral_filter(std_median_out, std_final_out, width, height, 0.5, 15.0);
    auto end_std = std::chrono::high_resolution_clock::now();
    auto duration_std = std::chrono::duration_cast<std::chrono::microseconds>(end_std - start_std);

    // 2. Chạy Pipeline Phần Cứng (Approximate / RTL)
    auto start_rtl = std::chrono::high_resolution_clock::now();
    run_rtl_switching_median(noisy, rtl_median_out, threshold, width, height);
    run_rtl_bilateral_filter(rtl_median_out, rtl_final_out, width, height);
    auto end_rtl = std::chrono::high_resolution_clock::now();
    auto duration_rtl = std::chrono::duration_cast<std::chrono::microseconds>(end_rtl - start_rtl);

    // 3. Tính toán Metrics
    double mse_std = 0, mae_std = 0;
    compute_metrics(original, std_final_out, width, height, mse_std, mae_std);

    double mse_rtl = 0, mae_rtl = 0;
    compute_metrics(original, rtl_final_out, width, height, mse_rtl, mae_rtl);

    stbi_write_png("1_noisy_image.png", width, height, 1, noisy.data(), width);
    stbi_write_png("2_standard_final.png", width, height, 1, std_final_out.data(), width);
    stbi_write_png("3_rtl_final.png", width, height, 1, rtl_final_out.data(), width);

    std::cout << "=================================================\n";
    std::cout << "        SO SÁNH LÝ THUYẾT VÀ KIẾN TRÚC RTL       \n";
    std::cout << "=================================================\n";
    std::cout << "[1] PIPELINE CHUẨN LÝ THUYẾT (Floating-point exp)\n";
    std::cout << "    -> Final MSE: " << mse_std << " | MAE: " << mae_std << "\n";
    std::cout << "    -> Core Time: " << duration_std.count() / 1000.0 << " ms\n";
    std::cout << "-------------------------------------------------\n";
    std::cout << "[2] PIPELINE PHẦN CỨNG RTL (Approx LUT & Shift)\n";
    std::cout << "    -> Final MSE: " << mse_rtl << " | MAE: " << mae_rtl << "\n";
    std::cout << "    -> Core Time: " << duration_rtl.count() / 1000.0 << " ms\n";
    std::cout << "-------------------------------------------------\n";
    std::cout << " -> Tốc độ tăng tốc trên C++ (Phần mềm): " << (double)duration_std.count() / duration_rtl.count() << "x lần.\n";
    std::cout << "=================================================\n";
    
    return 0;
}