import numpy as np

W = 4
H = 4
TOTAL_PIXELS = W * H

# 1. TẠO ẢNH TEST PATTERN VÀ LƯU FILE HEX
img = np.zeros((H, W), dtype=int)
img[:, :W//2] = 10
img[:, W//2:] = 90

with open("input_img.hex", "w") as f:
    for val in img.flatten():
        f.write(f"{val:02X}\n")

# 2. XỬ LÝ SOBEL GOLDEN MODEL (Bao gồm cả viền giả lập RTL)
kernel = np.array([[-1, 0, 1],
                   [-2, 0, 2],
                   [-1, 0, 1]])
                   
expected_pixels = []
padded_img = np.pad(img, pad_width=1, mode='constant', constant_values=0)

for y in range(1, H + 1):
    for x in range(1, W + 1):
        window = padded_img[y-1:y+2, x-1:x+2]
        mac_abs = abs(np.sum(window * kernel))
        expected_pixels.append(255 if mac_abs > 255 else int(mac_abs))

# 3. KIỂM TRA CHÉO VỚI DỮ LIỆU RTL
try:
    with open("output_img.hex", 'r') as f:
        # Ép kiểu chữ hoa và lọc rác
        rtl_lines = [l.strip().upper() for l in f.readlines() if l.strip()]
        
    # Cắt bỏ toàn bộ Ghost Pixels dư thừa ở đuôi
    rtl_valid = rtl_lines[:TOTAL_PIXELS]
    exp_valid = [f"{val:02X}" for val in expected_pixels]

    mismatches = 0
    for i in range(TOTAL_PIXELS):
        if exp_valid[i] != rtl_valid[i]:
            print(f"Lệch tại Pixel {i+1}: Python = {exp_valid[i]}, RTL = {rtl_valid[i]}")
            mismatches += 1
            if mismatches >= 10: break

    if mismatches == 0:
        print("\n==================================================")
        print("🎉 CHÚC MỪNG! KẾT QUẢ KHỚP NHAU 100%.")
        print(" THIẾT KẾ PHẦN CỨNG RTL CHÍNH XÁC TUYỆT ĐỐI!")
        print("==================================================\n")
except FileNotFoundError:
    print("Vui lòng chạy lại Testbench trên ModelSim trước khi verify.")