import cv2
import numpy as np
import os

# ==========================================
# CẤU HÌNH THÔNG SỐ (PHẢI KHỚP VỚI VERILOG)
# ==========================================
INPUT_IMAGE = "images.jpeg"  # Tên ảnh biển báo gốc của bạn
HEX_FILE = "input_gaussian_noise.hex"       # File Hex sẽ xuất ra
VERIFY_IMAGE = "gaussian_noise_image.png"   # File ảnh kiểm chứng sinh ra từ Hex
WIDTH = 128                       # Chiều rộng ngõ vào phần cứng
HEIGHT = 128                      # Chiều cao ngõ vào phần cứng

# ==========================================
# BƯỚC 1: XỬ LÝ ẢNH GỐC VÀ XUẤT FILE HEX
# ==========================================
if not os.path.exists(INPUT_IMAGE):
    print(f"LỖI: Không tìm thấy file {INPUT_IMAGE}")
else:
    # 1. Đọc ảnh và ép buộc chuyển sang ảnh xám (Grayscale)
    img_gray = cv2.imread(INPUT_IMAGE, cv2.IMREAD_GRAYSCALE)
    # 2. Resize ảnh về đúng kích thước cấu hình (W x H)
    img_resized = cv2.resize(img_gray, (WIDTH, HEIGHT))
    # 3. Làm phẳng ảnh (Flatten) thành mảng 1D
    flattened_data = img_resized.flatten()
    # 4. Ghi ra file Hex (Định dạng 2 chữ số Hex, viết hoa)
    with open(HEX_FILE, "w") as f:
        for pixel in flattened_data:
            f.write(f"{pixel:02X}\n")
    print(f"✅ BƯỚC 1: Đã xuất thành công {len(flattened_data)} pixel (Kích thước {WIDTH}x{HEIGHT}) ra file {HEX_FILE}.")
# ==========================================
# BƯỚC 2: ĐỌC LẠI FILE HEX ĐỂ KIỂM CHỨNG (MÔ PHỎNG NGÕ RA)
# ==========================================
try:
    # 1. Đọc từng dòng trong file Hex, ép về cơ số 16 (Hex to Int)
    with open(HEX_FILE, "r") as f:
        hex_lines = f.readlines()
   
    recovered_pixels = np.array([int(line.strip(), 16) for line in hex_lines], dtype=np.uint8)
    
    # 2. CỐT LÕI: Reshape mảng 1D về lại kích thước 2D. 
    # Nếu chiều dài mảng không bằng W * H, lệnh này sẽ báo lỗi ngay!
    recovered_img = recovered_pixels.reshape((HEIGHT, WIDTH))
    
    # 3. Lưu ảnh kiểm chứng
    cv2.imwrite(VERIFY_IMAGE, recovered_img)
    print(f"✅ BƯỚC 2: Đã tạo ảnh kiểm chứng tại {VERIFY_IMAGE}.")
    print("👉 Hãy mở file 'verify_hex.png' lên. Nếu ảnh hình tròn hoàn hảo, file Hex của bạn đã chuẩn 100%!")
    
except ValueError as e:
    print("❌ LỖI RESHAPE: Số lượng dữ liệu trong file Hex không khớp với kích thước HEIGHT * WIDTH bạn cài đặt!")
    print(f"Chi tiết lỗi từ Python: {e}")
except Exception as e:
    print(f"❌ Có lỗi bất ngờ xảy ra ở BƯỚC 2: {e}")