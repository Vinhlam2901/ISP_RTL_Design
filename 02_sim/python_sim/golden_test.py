import numpy as np
W = 4
H = 4
# ---------------------------------------------------------
# 1. TẠO ẢNH TEST (Test Pattern)
# ---------------------------------------------------------
# Tạo ảnh 16x16: nửa trái giá trị 10, nửa phải giá trị 90
img = np.zeros((H, W), dtype=int)
img[:, :W//2] = 10
img[:, W//2:] = 90
# Ghi file input.hex để nạp vào Testbench
with open("input_img.hex", "w") as f:
  for val in img.flatten():
      f.write(f"{val:02X}\n")
print(f"Đã tạo [input_img.hex] kích thước {W}x{H} ({W*H} pixels).")
# ---------------------------------------------------------
# 2. CHẠY THUẬT TOÁN GOLDEN MODEL
# ---------------------------------------------------------
# Ma trận Sobel X
kernel = np.array([[-1, 0, 1],
                   [-2, 0, 2],
                   [-1, 0, 1]])
expected_pixels = []
# Quét qua vùng lõi (Bỏ 1 pixel viền hệt như tín hiệu window_err của RTL)
for y in range(1, H-1):
    for x in range(1, W-1):
        # Trích xuất cửa sổ 3x3
        window = img[y-1:y+2, x-1:x+2]
        # Bước 1: Khối MAC (Nhân - Cộng)
        mac_sum = np.sum(window * kernel)
        # Bước 2: Lấy trị tuyệt đối (Giống hệt mac_abs)
        mac_abs = abs(mac_sum)
        # Bước 3: Cắt bão hòa 255 (Giống hệt khâu Saturation)
        if mac_abs > 255:
            pix_out = 255
        else:
            pix_out = int(mac_abs)
        expected_pixels.append(pix_out)
# Ghi kết quả tính tay ra file expected.hex
with open("expected.hex", "w") as f:
    for val in expected_pixels:
        f.write(f"{val:02X}\n")
print(f"Đã tính xong Golden Model và tạo [expected.hex] ({len(expected_pixels)} pixels lõi).")