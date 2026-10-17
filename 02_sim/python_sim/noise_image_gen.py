import numpy as np
import cv2

# 1. Đọc bức ảnh có sẵn
image_path = "test.jpg"  
img_clean = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)

if img_clean is None:
    print(f"Lỗi: Không tìm thấy ảnh tại '{image_path}'. Vui lòng kiểm tra lại đường dẫn!")
else:
    # Cấu hình kích thước chuẩn cho phần cứng
    H = 256
    W = 256
    
    # BƯỚC QUAN TRỌNG: Resize ảnh gốc về đúng 128x128
    img_resized = cv2.resize(img_clean, (W, H))
    
    # 2. Tạo nhiễu phân bố chuẩn (Gaussian Noise)
    mean = 0       
    sigma = 15
    gauss_noise = np.random.normal(mean, sigma, (H, W))
    
    # Tiêm nhiễu Gaussian vào ảnh ĐÃ RESIZE
    img_noisy = img_resized + gauss_noise
    img_noisy = np.clip(img_noisy, 0, 255).astype(np.uint8)
    
    # 3. Tiêm thêm nhiễu Muối Tiêu (Salt & Pepper Noise)
    noise_ratio = 0.05  # Mật độ nhiễu 5% tổng số pixel
    num_noise_pixels = int(noise_ratio * H * W)
    
    # Tạo ngẫu nhiên tọa độ cho nhiễu Muối (Trắng - 255)
    num_salt = num_noise_pixels // 2
    salt_y = np.random.randint(0, H, num_salt)
    salt_x = np.random.randint(0, W, num_salt)
    img_noisy[salt_y, salt_x] = 255
    
    # Tạo ngẫu nhiên tọa độ cho nhiễu Tiêu (Đen - 0)
    num_pepper = num_noise_pixels // 2
    pepper_y = np.random.randint(0, H, num_pepper)
    pepper_x = np.random.randint(0, W, num_pepper)
    img_noisy[pepper_y, pepper_x] = 0

    # 4. Xuất ra file Hex để nạp vào Verilog Testbench
    hex_filename = "input_mixed_noise.hex"
    with open(hex_filename, "w") as f:
        for val in img_noisy.flatten():
            f.write(f"{val:02X}\n")
            
    # Xuất ra file ảnh output để kiểm tra bằng mắt
    output_image_name = "mixed_noise_image.png"
    cv2.imwrite(output_image_name, img_noisy)
    
    print(f"Thành công! Đã tạo ảnh nhiễu hỗn hợp kích thước {W}x{H}.")
    print(f"File Hex được lưu tại: {hex_filename}")