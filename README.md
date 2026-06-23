# Vietnamese Product Clustering

Dự án so sánh ba cách biểu diễn văn bản để phân cụm mô tả sản phẩm:

- TF-IDF kết hợp Truncated SVD
- PhoBERT (`vinai/phobert-large`)
- E5 đa ngôn ngữ (`intfloat/multilingual-e5-large`)

Ba thuật toán phân cụm được đánh giá là K-Means, DBSCAN và Gaussian Mixture Model. Notebook chính lưu toàn bộ quy trình tạo embedding, tìm tham số và tính các chỉ số Silhouette, Davies-Bouldin, Calinski-Harabasz, NMI, ARI và Purity.

## Kết quả

Bảng sau tổng hợp kết quả của ba cách biểu diễn văn bản. Silhouette, CH, NMI,
ARI và Purity càng cao càng tốt; DBI càng thấp càng tốt.

| Biểu diễn | Mô hình | Silhouette | DBI | CH | NMI | ARI | Purity |
|---|---|---:|---:|---:|---:|---:|---:|
| TF-IDF + SVD | K-Means | 0.297 | 2.510 | 1328.53 | 0.902 | 0.864 | 0.924 |
| TF-IDF + SVD | DBSCAN | 0.986 | 0.116 | 16175.46 | 0.092 | 0.003 | 0.156 |
| TF-IDF + SVD | GMM | 0.276 | 2.784 | 1275.06 | 0.835 | 0.748 | 0.862 |
| PhoBERT | K-Means | 0.205 | 2.299 | 2418.46 | 0.548 | 0.378 | 0.533 |
| PhoBERT | DBSCAN | 0.556 | 0.837 | 48.36 | 0.006 | 0.001 | 0.111 |
| PhoBERT | GMM | 0.264 | 2.182 | 4331.95 | 0.300 | 0.116 | 0.268 |
| Multilingual E5 | K-Means | 0.166 | 2.855 | 1471.18 | 0.851 | 0.636 | 0.658 |
| Multilingual E5 | DBSCAN | 0.670 | 0.844 | 275.12 | 0.758 | 0.528 | 1.000 |
| Multilingual E5 | GMM | 0.183 | 3.005 | 1360.81 | **0.913** | **0.820** | 0.792 |

Xét theo nhãn tham chiếu, GMM trên Multilingual E5 đạt NMI và ARI cao nhất.
K-Means trên TF-IDF + SVD đạt Purity 0.924, đồng thời cho kết quả cân bằng
tốt trên cả ba chỉ số NMI, ARI và Purity. Kết quả DBSCAN cần được đọc thận
trọng: điểm nội tại cao không đồng nghĩa với khả năng khôi phục các nhóm sản
phẩm, như thể hiện ở DBSCAN trên TF-IDF + SVD.

Số liệu đầy đủ được lưu tại:

- `social_networking/traditional/evaluation_traditional.csv`
- `social_networking/pho_bert/clustering/evaluation_phobert.csv`
- `social_networking/multilingual/clustering/evaluation_multilingual.csv`

Dữ liệu gốc, embedding, model đã fit và các file trung gian không được đưa lên
Git vì có kích thước lớn và có thể tái tạo. Chúng được loại bỏ bởi `.gitignore`.

## Cấu trúc

```text
.
|-- preprocess.R               # Gộp và tiền xử lý dữ liệu chung
|-- prepare_phobert.R          # Chuẩn bị dữ liệu riêng cho PhoBERT
|-- social_networking/
|   |-- main.ipynb             # Pipeline embedding và phân cụm
|   |-- multilingual/          # Kết quả E5 đa ngôn ngữ
|   |-- pho_bert/              # Kết quả PhoBERT
|   `-- traditional/           # Kết quả TF-IDF + SVD
|-- requirements.txt           # Dependency Python
`-- requirements-r.txt         # Dependency R
```

## Chuẩn bị môi trường

Yêu cầu Python 3.10+, R 4.2+ và Java 8+ (cho VnCoreNLP).

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

Cài các gói R được liệt kê trong `requirements-r.txt`:

```r
install.packages(readLines("requirements-r.txt"))
```

## Dữ liệu đầu vào

Đặt `mota1.csv` đến `mota14.csv` tại thư mục gốc. Mỗi file cần có các cột:

```text
category_name,product_name,product_url,description
```

Dữ liệu không được phân phối kèm repo. Người dùng tự chịu trách nhiệm về quyền sử dụng và việc loại bỏ thông tin nhạy cảm trước khi xử lý.

## Chạy pipeline

1. Chạy `Rscript preprocess.R` để gộp dữ liệu và tạo đầu vào cho pipeline đa ngôn ngữ/truyền thống.
2. Mở `prepare_phobert.R` trong RStudio và chạy từng pha. Dừng sau Pha A, lọc thủ công danh sách token trong `auto_english_candidates.csv`, sau đó mới chạy Pha B và các bước DF >= 5. Không chạy toàn bộ file một lần vì bước lọc này cần quyết định của người dùng.
3. Mở repo làm thư mục làm việc, sau đó chạy `social_networking/main.ipynb` theo thứ tự cell.

Notebook chỉ dùng đường dẫn tương đối. Các thư mục output sẽ được tạo trong `social_networking/` và không được Git theo dõi.

## Tái lập và giới hạn

- Seed của các mô hình phân cụm được đặt là `42` ở những nơi thư viện hỗ trợ.
- Kết quả có thể thay đổi theo phiên bản dependency, phần cứng và tập dữ liệu đầu vào.
- Notebook là quy trình nghiên cứu, không phải dịch vụ production.
- Các file đánh giá trong repo là kết quả của lần chạy hiện có; chúng không được CI tính lại vì cần dữ liệu và tài nguyên GPU/CPU lớn.

## License

Mã nguồn được phát hành theo giấy phép MIT. Dữ liệu, model của bên thứ ba và trọng số tải về từ Hugging Face tuân theo giấy phép riêng của từng nguồn.
