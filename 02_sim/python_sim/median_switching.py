import numpy as np
import cv2
import matplotlib.pyplot as plt
from scipy.ndimage import convolve, median_filter
def add_impulse_noise(image, prob=0.1):
    """
    Hàm tạo nhiễu xung (Salt & Pepper).
    prob: Tỷ lệ nhiễu (ví dụ 0.1 nghĩa là 10% điểm ảnh bị nhiễu).
    """
    noisy_image = np.copy(image)
    # Tạo một ma trận ngẫu nhiên cùng kích thước với ảnh, giá trị từ 0.0 đến 1.0
    rand_matrix = np.random.rand(image.shape[0], image.shape[1])
    
    # Một nửa số điểm nhiễu sẽ là nhiễu hạt tiêu (Pepper - màu đen = 0)
    noisy_image[rand_matrix < (prob / 2)] = 0
    # Một nửa còn lại là nhiễu muối (Salt - màu trắng = 255)
    noisy_image[rand_matrix > 1 - (prob / 2)] = 255
    return noisy_image
def switching_median_filter_visualized(image_path, T=40, noise_prob=0.1):
    # 0. Đọc ảnh gốc và chèn nhiễu
    original_img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
    if original_img is None:
        print("Lỗi: Không tìm thấy ảnh đầu vào!")
        return   
    noisy_img = add_impulse_noise(original_img, prob=noise_prob)
    img_float = noisy_img.astype(np.float32)
    # 1. Định nghĩa 4 Kernels 3x3 (1D Laplacian)
    K_h  = np.array([[ 0,  0,  0], [-1,  2, -1], [ 0,  0,  0]])
    K_v  = np.array([[ 0, -1,  0], [ 0,  2,  0], [ 0, -1,  0]])
    K_d1 = np.array([[-1,  0,  0], [ 0,  2,  0], [ 0,  0, -1]])
    K_d2 = np.array([[ 0,  0, -1], [ 0,  2,  0], [-1,  0,  0]])
    # 2. Tích chập song song 4 hướng
    C_h  = np.abs(convolve(img_float, K_h, mode='reflect'))
    C_v  = np.abs(convolve(img_float, K_v, mode='reflect'))
    C_d1 = np.abs(convolve(img_float, K_d1, mode='reflect'))
    C_d2 = np.abs(convolve(img_float, K_d2, mode='reflect'))
    # 3. Tìm độ lệch nhỏ nhất r_ij
    r_ij = np.minimum.reduce([C_h, C_v, C_d1, C_d2])
    # 4. Tính Trung vị (Blind Median)
    y_med = median_filter(img_float, size=3, mode='reflect')
    # 5. Phân loại nhiễu và Chuyển mạch
    noise_flag = r_ij >= T
    output_img = np.where(noise_flag, y_med, img_float)
    # Ép kiểu về uint8
    output_img = np.clip(output_img, 0, 255).astype(np.uint8)
    # ==========================================
    # HIỂN THỊ KẾT QUẢ TỪNG BƯỚC BẰNG MATPLOTLIB
    # ==========================================
    plt.figure(figsize=(15, 10))
    plt.suptitle(f"Quy trình Switching Median Filter (Ngưỡng T={T})", fontsize=16, fontweight='bold')
    # Bước 0: Ảnh đầu vào đã chèn nhiễu
    plt.subplot(2, 3, 1)
    plt.imshow(noisy_img, cmap='gray', vmin=0, vmax=255)
    plt.title("1. Ảnh đầu vào (Có nhiễu xung)")
    plt.axis('off')
    # Bước 3: Ma trận r_ij (Trực quan hóa độ lệch)
    plt.subplot(2, 3, 2)
    # Hiển thị r_ij. Các điểm sáng chói là nhiễu, điểm tối là nền hoặc cạnh ảnh
    plt.imshow(r_ij, cmap='hot')
    plt.title("2. Độ lệch r_ij (Sau tích chập)")
    plt.axis('off')
    # Bước 4: Kết quả của Blind Median Filter (Mạch dự phòng)
    plt.subplot(2, 3, 3)
    plt.imshow(y_med, cmap='gray', vmin=0, vmax=255)
    plt.title("3. Lọc trung vị toàn bộ (Bị mờ)")
    plt.axis('off')

    # Bước 5.1: Cờ báo nhiễu (Tín hiệu điều khiển MUX)
    plt.subplot(2, 3, 4)
    plt.imshow(noise_flag, cmap='gray')
    plt.title("4. Cờ báo nhiễu (Trắng = Lỗi, Đen = Sạch)")
    plt.axis('off')

    # Bước 5.2: Kết quả cuối cùng sau khi Switching
    plt.subplot(2, 3, 5)
    plt.imshow(output_img, cmap='gray', vmin=0, vmax=255)
    plt.title("5. Kết quả (Switching Median)")
    plt.axis('off')

    # Ảnh gốc (để so sánh)
    plt.subplot(2, 3, 6)
    plt.imshow(original_img, cmap='gray', vmin=0, vmax=255)
    plt.title("Ảnh gốc (Clean Reference)")
    plt.axis('off')

    plt.tight_layout()
    plt.show()

# THỰC THI CHƯƠNG TRÌNH
# Bạn cần chuẩn bị một tấm ảnh đuôi .jpg hoặc .png để chạy thử nghiệm
# Thay 'your_image.jpg' bằng đường dẫn tới ảnh thật của bạn.
if __name__ == "__main__":
    # Ví dụ: Mức nhiễu 10% (0.1) và Ngưỡng T = 40
    switching_median_filter_visualized("images.jpeg", T=100, noise_prob=0.2)