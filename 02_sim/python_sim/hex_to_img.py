import numpy as np
from PIL import Image
# Giữ nguyên thông số phần cứng 128x128
WIDTH = 128
HEIGHT = 128
VALID_TOTAL = WIDTH * HEIGHT
def hex_to_image(input_hex, output_img):
    pixels = []
    with open(input_hex, 'r') as f:
        for line in f:
            val = line.strip()
            if val:
                pixels.append(int(val, 16))      
    total_pixels = len(pixels)
    print(f"Tổng số điểm ảnh nhận được: {total_pixels}")
    # Cắt bỏ chính xác phần rác đuôi do Pipeline của Testbench sinh ra
    if total_pixels > VALID_TOTAL:
        pixels = pixels[:VALID_TOTAL]
    elif total_pixels < VALID_TOTAL:
        pixels.extend([0] * (VALID_TOTAL - total_pixels))
    # Định dạng lại ma trận và xuất ảnh
    pixel_array = np.array(pixels, dtype=np.uint8)
    final_matrix = pixel_array.reshape((HEIGHT, WIDTH))
    img_out = Image.fromarray(final_matrix, mode='L')
    img_out.save(output_img)
    print(f"Hoàn tất! Bức ảnh chuẩn xác đã được lưu tại: {output_img}")
    img_out.show()

hex_to_image("output_img.hex", "output_img.png")