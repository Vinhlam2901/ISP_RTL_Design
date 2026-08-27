import numpy as np
import cv2
# 1. Đọc bức ảnh có sẵn
image_path = "images.jpeg"  
img_clean = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
# Kiểm tra xem ảnh có tồn tại không
if img_clean is None:
    print(f"Lỗi: Không tìm thấy ảnh tại '{image_path}'. Vui lòng kiểm tra lại đường dẫn!")
else:
    # Cấu hình kích thước chuẩn cho phần cứng
    H = 128
    W = 128
    # BƯỚC QUAN TRỌNG: Resize ảnh gốc về đúng 128x128
    img_resized = cv2.resize(img_clean, (W, H))
    # 2. Tạo nhiễu phân bố chuẩn (Gaussian Noise) với ma trận 128x128
    mean = 0       
    sigma = 50     
    gauss_noise = np.random.normal(mean, sigma, (H, W))
    # 3. Tiêm nhiễu vào ảnh ĐÃ RESIZE
    # Lúc này cả 2 ma trận đều là 128x128 nên cộng lại sẽ hoàn hảo
    img_noisy = img_resized + gauss_noise
    # Ép kiểu dữ liệu về 8-bit (0 đến 255)
    img_noisy = np.clip(img_noisy, 0, 255).astype(np.uint8)
    # 4. Xuất ra file Hex để nạp vào Verilog Testbench
    hex_filename = "input_gaussian_noise.hex"
    with open(hex_filename, "w") as f:
        for val in img_noisy.flatten():
            f.write(f"{val:02X}\n")
    # Xuất ra file ảnh output để kiểm tra bằng mắt
    output_image_name = "gaussian_noise_image.png"
    cv2.imwrite(output_image_name, img_noisy)
    print(f"Thành công! Đã tạo ảnh nhiễu kích thước {W}x{H}.")
    print(f"File Hex được lưu tại: {hex_filename}")