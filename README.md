# Vietnamese Product Clustering

Du an so sanh ba cach bieu dien van ban de phan cum mo ta san pham:

- TF-IDF ket hop Truncated SVD
- PhoBERT (`vinai/phobert-large`)
- E5 da ngon ngu (`intfloat/multilingual-e5-large`)

Ba thuat toan phan cum duoc danh gia la K-Means, DBSCAN va Gaussian Mixture Model. Notebook chinh luu toan bo quy trinh tao embedding, tim tham so va tinh cac chi so Silhouette, Davies-Bouldin, Calinski-Harabasz, NMI, ARI va Purity.

## Ket qua hien co

Ket qua tong hop nho duoc luu trong repo:

- `social_networking/traditional/evaluation_traditional.csv`
- `social_networking/pho_bert/clustering/evaluation_phobert.csv`
- `social_networking/multilingual/clustering/evaluation_multilingual.csv`

Du lieu goc, embedding, model da fit va cac file trung gian khong duoc dua len Git vi co kich thuoc lon va co the tai tao. Chúng duoc loai bo boi `.gitignore`.

## Cau truc

```text
.
|-- preprocess.R               # Gop va tien xu ly du lieu chung
|-- prepare_phobert.R          # Chuan bi du lieu rieng cho PhoBERT
|-- social_networking/
|   |-- main.ipynb             # Pipeline embedding va phan cum
|   |-- multilingual/          # Ket qua E5 da ngon ngu
|   |-- pho_bert/              # Ket qua PhoBERT
|   `-- traditional/           # Ket qua TF-IDF + SVD
|-- requirements.txt           # Dependency Python
`-- requirements-r.txt         # Dependency R
```

## Chuan bi moi truong

Yeu cau Python 3.10+, R 4.2+ va Java 8+ (cho VnCoreNLP).

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

Cai cac goi R duoc liet ke trong `requirements-r.txt`:

```r
install.packages(readLines("requirements-r.txt"))
```

## Du lieu dau vao

Dat `mota1.csv` den `mota14.csv` tai thu muc goc. Moi file can co cac cot:

```text
category_name,product_name,product_url,description
```

Du lieu khong duoc phan phoi kem repo. Nguoi dung tu chiu trach nhiem ve quyen su dung va viec loai bo thong tin nhay cam truoc khi xu ly.

## Chay pipeline

1. Chay `Rscript preprocess.R` de gop du lieu va tao dau vao cho pipeline da ngon ngu/truyen thong.
2. Mo `prepare_phobert.R` trong RStudio va chay tung pha. Dung sau Pha A, loc thu cong danh sach token trong `auto_english_candidates.csv`, sau do moi chay Pha B va cac buoc DF >= 5. Khong chay toan bo file mot lan vi buoc loc nay can quyet dinh cua nguoi dung.
3. Mo repo lam thu muc lam viec, sau do chay `social_networking/main.ipynb` theo thu tu cell.

Notebook chi dung duong dan tuong doi. Cac thu muc output se duoc tao trong `social_networking/` va khong duoc Git theo doi.

## Tai lap va gioi han

- Seed cua cac mo hinh phan cum duoc dat la `42` o nhung noi thu vien ho tro.
- Ket qua co the thay doi theo phien ban dependency, phan cung va tap du lieu dau vao.
- Notebook la quy trinh nghien cuu, khong phai dich vu production.
- Cac file danh gia trong repo la ket qua cua lan chay hien co; chung khong duoc CI tinh lai vi can du lieu va tai nguyen GPU/CPU lon.

## License

Ma nguon duoc phat hanh theo giay phep MIT. Du lieu, model cua ben thu ba va trong so tai ve tu Hugging Face tuan theo giay phep rieng cua tung nguon.
