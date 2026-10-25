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
// HÀM SẮP XẾP 3 PHẦN TỬ (Dùng cho 3x3)
// =========================================================================================
void sort3(int a, int b, int c, int& min_val, int& med_val, int& max_val) {
    int arr[3] = {a, b, c};
    std::sort(arr, arr + 3); 
    min_val = arr[0];
    med_val = arr[1];
    max_val = arr[2];
}
int get_AWr(int diff) {
    if (diff < 4)  return 64; if (diff < 7)  return 60; if (diff < 10) return 56;
    if (diff < 13) return 48; if (diff < 17) return 40; if (diff < 20) return 32;
    if (diff < 22) return 24; if (diff < 24) return 20; if (diff < 27) return 16;
    if (diff < 29) return 12; if (diff < 33) return 8;  if (diff < 38) return 4;
    if (diff < 40) return 2;  if (diff < 44) return 1;  return 0;
}
// =========================================================================================
// [1] KIẾN TRÚC 3x3 (RTL MODEL HIỆN TẠI)
// =========================================================================================
void run_rtl_switching_median_3x3(const std::vector<uint8_t>& input, std::vector<uint8_t>& output, uint8_t threshold, int width, int height) {
    output = input; 
    for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) { 
            int p00 = input[(y - 1) * width + (x - 1)]; int p01 = input[(y - 1) * width + (x + 0)]; int p02 = input[(y - 1) * width + (x + 1)];
            int p10 = input[(y + 0) * width + (x - 1)]; int p11 = input[(y + 0) * width + (x + 0)]; int p12 = input[(y + 0) * width + (x + 1)];
            int p20 = input[(y + 1) * width + (x - 1)]; int p21 = input[(y + 1) * width + (x + 0)]; int p22 = input[(y + 1) * width + (x + 1)];

            int min_r1, med_r1, max_r1, min_r2, med_r2, max_r2, min_r3, med_r3, max_r3;
            sort3(p00, p01, p02, min_r1, med_r1, max_r1); sort3(p10, p11, p12, min_r2, med_r2, max_r2); sort3(p20, p21, p22, min_r3, med_r3, max_r3);
            int dummy_min, dummy_med, dummy_max, max_of_mins, med_of_meds, min_of_maxs;
            sort3(min_r1, min_r2, min_r3, dummy_min, dummy_med, max_of_mins);
            sort3(med_r1, med_r2, med_r3, dummy_min, med_of_meds, dummy_max);
            sort3(max_r1, max_r2, max_r3, min_of_maxs, dummy_med, dummy_max);

            int final_median;
            sort3(max_of_mins, med_of_meds, min_of_maxs, dummy_min, final_median, dummy_max);

            int center_sl   = p11 * 2; 
            int vert_dev    = std::min(255, std::abs((p21 + p01) - center_sl));
            int hor_dev     = std::min(255, std::abs((p12 + p10) - center_sl));
            int crossl_dev  = std::min(255, std::abs((p22 + p00) - center_sl));
            int crossr_dev  = std::min(255, std::abs((p20 + p02) - center_sl));

            int min_vh  = std::min(vert_dev, hor_dev);
            int min_lr  = std::min(crossl_dev, crossr_dev);
            int min_all = std::min(min_vh, min_lr);

            if (min_all >= threshold) output[y * width + x] = final_median; 
            else output[y * width + x] = p11;          
        }
    }
}

void run_rtl_bilateral_filter_3x3(const std::vector<uint8_t>& input, std::vector<uint8_t>& output, int width, int height) {
    output = input; 
    for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
            long long numerator = 0;
            int denominator = 0;
            int center = input[y * width + x];

            for (int ky = -1; ky <= 1; ky++) {
                for (int kx = -1; kx <= 1; kx++) {
                    int neighbor = input[(y + ky) * width + (x + kx)];
                    int abs_diff = std::abs(neighbor - center);
                    int awr = get_AWr(abs_diff);

                    int dist_sq = kx*kx + ky*ky;
                    int w_total = 0;
                    if (dist_sq == 0) w_total = awr << 6;
                    else if (dist_sq == 1) w_total = awr << 5;
                    else if (dist_sq == 2) w_total = awr << 4;

                    numerator += neighbor * w_total; 
                    denominator += w_total; 
                }
            }
            if (denominator == 0) denominator = 1; 
            output[y * width + x] = std::min(255LL, numerator / denominator);
        }
    }
}

// =========================================================================================
// [2] KIẾN TRÚC MỞ RỘNG 5x5 (HARDWARE APPROXIMATION MODEL)
// =========================================================================================
void run_rtl_switching_median_5x5(const std::vector<uint8_t>& input, std::vector<uint8_t>& output, uint8_t threshold, int width, int height) {
    output = input; 
    for (int y = 2; y < height - 2; y++) {
        for (int x = 2; x < width - 2; x++) { 
            int window[25];
            int idx = 0;
            for (int ky = -2; ky <= 2; ky++) {
                for (int kx = -2; kx <= 2; kx++) {
                    window[idx++] = input[(y + ky) * width + (x + kx)];
                }
            }
            // Mô phỏng mạng sắp xếp phần cứng 25 phần tử
            std::sort(window, window + 25);
            int final_median = window[12];
            int center = input[y * width + x];

            // Noise detection đơn giản hóa cho 5x5 để tiết kiệm logic
            if (std::abs(center - final_median) >= threshold) {
                output[y * width + x] = final_median; 
            } else {
                output[y * width + x] = center;          
            }
        }
    }
}

void run_rtl_bilateral_filter_5x5(const std::vector<uint8_t>& input, std::vector<uint8_t>& output, int width, int height) {
    output = input; 
    for (int y = 2; y < height - 2; y++) {
        for (int x = 2; x < width - 2; x++) {
            long long numerator = 0;
            int denominator = 0;
            int center = input[y * width + x];

            for (int ky = -2; ky <= 2; ky++) {
                for (int kx = -2; kx <= 2; kx++) {
                    int neighbor = input[(y + ky) * width + (x + kx)];
                    int abs_diff = std::abs(neighbor - center);
                    int awr = get_AWr(abs_diff);

                    // Ánh xạ khoảng cách không gian (d^2) sang phép dịch bit phần cứng
                    int dist_sq = kx*kx + ky*ky;
                    int w_total = 0;
                    if (dist_sq == 0)      w_total = awr << 6; // Center
                    else if (dist_sq == 1) w_total = awr << 5; // Trực tiếp bậc 1
                    else if (dist_sq == 2) w_total = awr << 4; // Chéo bậc 1
                    else if (dist_sq == 4) w_total = awr << 3; // Trực tiếp bậc 2
                    else if (dist_sq == 5) w_total = awr << 2; // Mã đi của ngựa
                    else if (dist_sq == 8) w_total = awr << 1; // Chéo bậc 2

                    numerator += neighbor * w_total; 
                    denominator += w_total; 
                }
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

    std::vector<uint8_t> median_out_3x3(total_pixels, 0); 
    std::vector<uint8_t> final_out_3x3(total_pixels, 0);
    std::vector<uint8_t> median_out_5x5(total_pixels, 0); 
    std::vector<uint8_t> final_out_5x5(total_pixels, 0);

    uint8_t threshold = 20;

    // 1. Chạy Pipeline 3x3
    auto start_3x3 = std::chrono::high_resolution_clock::now();
    run_rtl_switching_median_3x3(noisy, median_out_3x3, threshold, width, height);
    run_rtl_bilateral_filter_3x3(median_out_3x3, final_out_3x3, width, height);
    auto end_3x3 = std::chrono::high_resolution_clock::now();
    auto duration_3x3 = std::chrono::duration_cast<std::chrono::microseconds>(end_3x3 - start_3x3);

    // 2. Chạy Pipeline 5x5
    auto start_5x5 = std::chrono::high_resolution_clock::now();
    run_rtl_switching_median_5x5(noisy, median_out_5x5, threshold, width, height);
    run_rtl_bilateral_filter_5x5(median_out_5x5, final_out_5x5, width, height);
    auto end_5x5 = std::chrono::high_resolution_clock::now();
    auto duration_5x5 = std::chrono::duration_cast<std::chrono::microseconds>(end_5x5 - start_5x5);

    // 3. Tính toán Metrics
    double mse_3x3 = 0, mae_3x3 = 0;
    compute_metrics(original, final_out_3x3, width, height, mse_3x3, mae_3x3);

    double mse_5x5 = 0, mae_5x5 = 0;
    compute_metrics(original, final_out_5x5, width, height, mse_5x5, mae_5x5);

    stbi_write_png("3x3_rtl_final.png", width, height, 1, final_out_3x3.data(), width);
    stbi_write_png("5x5_rtl_final.png", width, height, 1, final_out_5x5.data(), width);

    std::cout << "=================================================\n";
    std::cout << "       SO SÁNH KIẾN TRÚC WINDOW 3x3 vs 5x5       \n";
    std::cout << "=================================================\n";
    std::cout << "[1] PIPELINE RTL 3x3 (9 Mẫu Điểm Ảnh)\n";
    std::cout << "    -> Final MSE: " << mse_3x3 << " | MAE: " << mae_3x3 << "\n";
    std::cout << "    -> Core Time: " << duration_3x3.count() / 1000.0 << " ms\n";
    std::cout << "-------------------------------------------------\n";
    std::cout << "[2] PIPELINE RTL 5x5 (25 Mẫu Điểm Ảnh)\n";
    std::cout << "    -> Final MSE: " << mse_5x5 << " | MAE: " << mae_5x5 << "\n";
    std::cout << "    -> Core Time: " << duration_5x5.count() / 1000.0 << " ms\n";
    std::cout << "=================================================\n";
    
    return 0;
}