import cv2
import numpy as np
import os

def image_to_hex(image_path, hex_path, width=256, height=256):
    """Chuyển ảnh thành file .hex để đưa vào Testbench"""
    # Đọc ảnh ở chế độ Grayscale
    img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
    if img is None:
        print(f"Không tìm thấy ảnh: {image_path}")
        return
    # Resize ảnh về đúng kích thước mạch phần cứng hỗ trợ
    img = cv2.resize(img, (width, height))
    # Ghi ra file hex
    with open(hex_path, 'w') as f:
        for row in img:
            for pixel in row:
                f.write(f"{pixel:02x}\n") # Ghi chuẩn Hex 2 số (00 đến ff)
    print(f"[THÀNH CÔNG] Đã tạo file: {hex_path}")

def hex_to_image(hex_path, image_path, width=256, height=256):
    import os
    import numpy as np
    import cv2
    
    if not os.path.exists(hex_path):
        print(f"Không tìm thấy file kết quả: {hex_path}")
        return
        
    pixels = []
    with open(hex_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line: 
                pixels.append(int(line, 16))
                
    # --- ĐOẠN CODE XỬ LÝ FIX LỖI ---
    expected_size = width * height
    current_size = len(pixels)
    
    if current_size < expected_size:
        print(f"Cảnh báo: Thiếu {expected_size - current_size} pixels. Đang tự động bù viền đen.")
        pixels.extend([0] * (expected_size - current_size))
    elif current_size > expected_size:
        print(f"Cảnh báo: Dư {current_size - expected_size} pixels. Đang cắt bỏ phần thừa.")
        pixels = pixels[:expected_size]
    # -------------------------------
                
    img_array = np.array(pixels, dtype=np.uint8).reshape((height, width))
    cv2.imwrite(image_path, img_array)
    print(f"[THÀNH CÔNG] Đã lưu ảnh kết quả: {image_path}")

# Hướng dẫn sử dụng:
if __name__ == "__main__":
    # 1. Chạy hàm này TRƯỚC khi mô phỏng (chuẩn bị đầu vào)
    image_to_hex('result_filtered.png', 'image_in.hex')
    
    # 2. Chạy hàm này SAU khi mô phỏng xong (xem kết quả)
    hex_to_image('image_out.hex', 'result_filtered.png')
    pass