import cv2
import numpy as np
import matplotlib.pyplot as plt
# --- CÁC HÀM TẠO NHIỄU & LỌC ---
def add_salt_and_pepper_noise(image, prob=0.05):
    noisy = np.copy(image)
    num_salt = np.ceil(prob * image.size * 0.5)
    coords = [np.random.randint(0, i, int(num_salt)) for i in image.shape]
    noisy[tuple(coords)] = 255
    num_pepper = np.ceil(prob * image.size * 0.5)
    coords = [np.random.randint(0, i, int(num_pepper)) for i in image.shape]
    noisy[tuple(coords)] = 0
    return noisy
def add_gaussian_noise(image, mean=0, std=25):
    gauss = np.random.normal(mean, std, image.shape)
    noisy = np.clip(image + gauss, 0, 255).astype(np.uint8)
    return noisy
def hw_switching_median_stage(image, kernel_size=3, threshold=50):
    """Mô phỏng Median Switching với Threshold"""
    median_filtered = cv2.medianBlur(image, kernel_size)
    # Tính độ chênh lệch tuyệt đối giữa pixel gốc và pixel trung vị
    diff = cv2.absdiff(image, median_filtered)
    # Chỉ thay thế những điểm có độ chênh lệch lớn hơn threshold
    noisy_mask = diff > threshold
    output = np.copy(image)
    output[noisy_mask] = median_filtered[noisy_mask]
    return output
def hw_bilateral_convolution_stage(image, sigma_s=3, sigma_c=100.0):
    """Mô phỏng Bilateral Filter bằng OpenCV"""
    # d=5 tương đương với window 5x5 (phù hợp với hardware 2-line buffer)
    return cv2.bilateralFilter(image, d=5, sigmaColor=sigma_c, sigmaSpace=sigma_s)
def calculate_psnr(img_clean, img_filtered):
    """Hàm tính toán sai số MSE và chỉ số PSNR"""
    mse = np.mean((img_clean.astype(float) - img_filtered.astype(float)) ** 2)
    if mse == 0:
        return 0, 100.0 # Bức ảnh hoàn hảo
    max_pixel = 255.0
    psnr = 20 * np.log10(max_pixel / np.sqrt(mse))
    return mse, psnr
# --- CHƯƠNG TRÌNH CHÍNH ---
if __name__ == "__main__":
    # 0. Nạp và thay đổi kích thước ảnh
    clean_img = cv2.imread('test.jpg', cv2.IMREAD_GRAYSCALE)
    if clean_img is None:
        raise ValueError("Không tìm thấy ảnh 'test.jpg'!")
    # Resize về 256x256 để chạy vòng lặp cho nhanh và sát với phần cứng
    clean_img = cv2.resize(clean_img, (256, 256), interpolation=cv2.INTER_AREA)
    # 1. Bơm Hỗn hợp Nhiễu (Cố định mức nhiễu để test nghiệm)
    img_with_gaussian = add_gaussian_noise(clean_img, mean=0, std=20)
    img_noisy_mixed = add_salt_and_pepper_noise(img_with_gaussian, prob=0.05)
    mse_in, psnr_in = calculate_psnr(clean_img, img_noisy_mixed)
    print(f"[*] PSNR đầu vào (Nhiễu hỗn hợp): {psnr_in:.2f} dB\n")
    # 2. KHỞI TẠO GRID SEARCH (Tự động quét tham số)
    # Bạn có thể thêm/bớt các thông số vào mảng này
    threshold_list = [50, 51, 52, 53, 54, 55, 60, 61, 62, 65]  
    sigma_c_list = [30.0, 80.0, 85.0, 90.0, 95.0, 100.0, 101.0, 102.0, 103.0, 104.0, 105.0, 110.0]
    best_psnr = 0
    best_params = {}
    best_final_img = None
    print(f"{'Threshold':<15} | {'Sigma_C':<15} | {'PSNR (dB)':<15}")
    print("-" * 50)
    # Vòng lặp quét mọi tổ hợp
    for th in threshold_list:
        # Chạy Stage 1 một lần cho mỗi threshold để tiết kiệm thời gian
        stage1_out = hw_switching_median_stage(img_noisy_mixed, threshold=th)   
        for sc in sigma_c_list:
            # Chạy Stage 2
            stage2_out = hw_bilateral_convolution_stage(stage1_out, sigma_s=3, sigma_c=sc)  
            # Đánh giá PSNR cuối cùng
            _, current_psnr = calculate_psnr(clean_img, stage2_out)     
            print(f"{th:<15} | {sc:<15} | {current_psnr:.2f}")
            # Lưu lại thông số tốt nhất
            if current_psnr > best_psnr:
                best_psnr = current_psnr
                best_params = {'threshold': th, 'sigma_c': sc}
                best_final_img = np.copy(stage2_out)
    print("-" * 50)
    print("\n[+] TÌM THẤY BỘ THÔNG SỐ TỐI ƯU NHẤT:")
    print(f"    - Switching Threshold : {best_params['threshold']}")
    print(f"    - Sigma Color (Wr)    : {best_params['sigma_c']}")
    print(f"    - Khôi phục PSNR lên mức : {best_psnr:.2f} dB")
    # 3. TRỰC QUAN HÓA KẾT QUẢ TỐT NHẤT
    titles = ['Ảnh gốc', 'Nhiễu Hỗn hợp', f'Kết quả tốt nhất (PSNR: {best_psnr:.2f}dB)']
    images = [clean_img, img_noisy_mixed, best_final_img]
    plt.figure(figsize=(12, 4))
    for i in range(3):
        plt.subplot(1, 3, i+1)
        plt.imshow(images[i], cmap='gray', vmin=0, vmax=255)
        plt.title(titles[i])
        plt.axis('off')
    plt.tight_layout()
    plt.show()