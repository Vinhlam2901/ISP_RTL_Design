from PIL import Image
# Cấu hình kích thước ảnh mô phỏng
WIDTH = 128
HEIGHT = 128
def image_to_hex(input_path, output_path):
    # 1. Mở ảnh và chuyển sang ảnh xám (L)
    img = Image.open(input_path).convert('L')
    # 2. Thay đổi kích thước cho khớp với phần cứng
    img = img.resize((WIDTH, HEIGHT))
    # 3. Trích xuất mảng điểm ảnh
    pixel_data = list(img.getdata())
    # 4. Ghi ra file text dưới định dạng Hex
    with open(output_path, 'w') as f:
        for pixel in pixel_data:
            f.write(f"{pixel:02X}\n")      
    print(f"Đã tạo file {output_path} thành công với {len(pixel_data)} pixels!")
# Chạy thử
image_to_hex("image_test.jpeg", "input_img.hex")