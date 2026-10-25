#include <iostream>
#include <vector>
#include <cmath>
#include <algorithm>
#include <chrono>

// Kích hoạt thư viện STB
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
    // Tên file ảnh đầu vào (Nên dùng ảnh Grayscale, đuôi PNG hoặc JPG)
    const char* input_image_path = "input_image.png"; 

    // Đọc ảnh thành mảng 1 chiều (Force 1 channel - Grayscale)
    unsigned char* img_data = stbi_load(input_image_path, &width, &height, &channels, 1);
    if (!img_data) {
        std::cerr << "[ERROR] Không thể tải ảnh: " << input_image_path << "\n";
        return -1;
    }

    std::cout << "[INFO] Đã tải ảnh: " << width << "x" << height << "\n";
    int total_pixels = width * height;

    std::vector<uint8_t> original(img_data, img_data + total_pixels);
    std::vector<uint8_t> noisy = original;
    stbi_image_free(img_data); // Giải phóng RAM

    // Bơm 5% nhiễu muối tiêu (Salt & Pepper)
    int noise_pixels = total_pixels * 0.05; 
    for (int i = 0; i < noise_pixels; i++) {
        int target = rand() % total_pixels;
        noisy[target] = (i % 2 == 0) ? 255 : 0; 
    }

    std::vector<uint8_t> stage1_median_out(total_pixels, 0); 
    std::vector<uint8_t> final_rtl_out(total_pixels, 0);

    uint8_t rtl_threshold = 20;

    // Chạy Pipeline và đo thời gian
    auto start_time = std::chrono::high_resolution_clock::now();
    run_rtl_switching_median(noisy, stage1_median_out, rtl_threshold, width, height);
    run_rtl_bilateral_filter(stage1_median_out, final_rtl_out, width, height);
    auto end_time = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end_time - start_time);

    // Tính toán Metrics
    double mse_rtl = 0, mae_rtl = 0;
    compute_metrics(original, final_rtl_out, width, height, mse_rtl, mae_rtl);

    // Xuất ra 3 file ảnh để đối chiếu
    stbi_write_png("1_noisy_image.png", width, height, 1, noisy.data(), width);
    stbi_write_png("2_median_stage.png", width, height, 1, stage1_median_out.data(), width);
    stbi_write_png("3_final_bilateral.png", width, height, 1, final_rtl_out.data(), width);

    // Báo cáo
    std::cout << "=================================================\n";
    std::cout << "  RTL PIPELINE BENCHMARK (REAL IMAGE TEST)       \n";
    std::cout << "=================================================\n";
    std::cout << " -> Final MSE: " << mse_rtl << " | MAE: " << mae_rtl << "\n";
    std::cout << " -> Core Time: " << duration.count() / 1000.0 << " ms\n";
    std::cout << " -> Đã xuất 3 file ảnh ra thư mục hiện tại để đối chiếu.\n";
    std::cout << "=================================================\n";
    
    return 0;
}