param([string]$DiaChi='http://127.0.0.1:5080/api/v1')
# Chạy với API/SQL Server trình diễn và tài khoản quản trị.
# Chỉ xử lý tên danh mục khớp chính xác "Gói MẪU " + 10 ký tự hex; giữ nguyên đơn hàng và lịch sử để đối chiếu.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Net.Http
$http=[System.Net.Http.HttpClient]::new()
$http.Timeout=[TimeSpan]::FromSeconds(30)
function Goi([string]$Cach,[string]$DuongDan,$NoiDung=$null,[string]$Token='',[int]$Ma=200) {
    $yeuCau=[System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::new($Cach),"$DiaChi/$DuongDan")
    $phanHoi=$null
    try {
        if($Token){$yeuCau.Headers.Authorization=[System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer',$Token)}
        if($null -ne $NoiDung){$yeuCau.Content=[System.Net.Http.StringContent]::new((ConvertTo-Json $NoiDung -Depth 20 -Compress),[Text.Encoding]::UTF8,'application/json')}
        $phanHoi=$http.SendAsync($yeuCau).GetAwaiter().GetResult()
        $vanBan=$phanHoi.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if([int]$phanHoi.StatusCode -ne $Ma){throw "API $DuongDan trả $([int]$phanHoi.StatusCode), mong đợi $Ma. $vanBan"}
        if($vanBan){return ($vanBan|ConvertFrom-Json)}
    } finally {if($phanHoi){$phanHoi.Dispose()};$yeuCau.Dispose()}
}
function DangNhap([string]$Email,[string]$MatKhau) {(Goi POST 'tai-khoan/dang-nhap' @{email=$Email;matKhau=$MatKhau}).maTruyCap}
try {
    $email=Read-Host 'Email quản trị'
    $matKhau=Read-Host 'Mật khẩu quản trị' -AsSecureString
    $token=DangNhap $email ([System.Net.NetworkCredential]::new('',$matKhau).Password)
    $mucTieu=@()
    $trang=1
    do {
        $danhSach=Goi GET "danh-muc?loai=DichVu&q=G%C3%B3i%20M%E1%BA%AAU&quanLy=true&trang=$trang" $null $token
        $mucTieu+=@($danhSach.duLieu|Where-Object { $_.ten -match '^Gói MẪU [0-9a-f]{10}$' })
        $trang++
    } while ($trang -le [Math]::Ceiling($danhSach.tong / $danhSach.kichThuoc))
    if($mucTieu.Count -eq 0){Write-Output 'Không tìm thấy danh mục kiểm thử có mã cần dọn.';return}
    foreach($danhMuc in $mucTieu) {
        if($danhMuc.ten -notmatch '^Gói MẪU ([0-9a-f]{10})$'){continue}
        $ma=$Matches[1]
        $id=[string]$danhMuc.id
        $goi=Goi GET "goi-luot?quanLy=true&danhMucId=$id&kichThuoc=50" $null $token
        $cacGoi=@($goi.duLieu)
        $mauDung=@("Cơ bản MẪU $ma","Tiết kiệm MẪU $ma")
        $ngoaiMau=@($cacGoi|Where-Object { $_.ten -notin $mauDung })
        if($ngoaiMau.Count -gt 0){
            Write-Warning "Bỏ qua '$($danhMuc.ten)': có gói không khớp mã kiểm thử; không thay đổi dữ liệu."
            continue
        }
        foreach($g in $cacGoi) {
            if($g.dangBan) {
                Goi PUT "goi-luot/$($g.id)" @{ten=$g.ten;moTa=$g.moTa;danhMucId=$g.danhMucId;anhId=$g.anhId;soLuot=$g.soLuot;gia=$g.gia;dangBan=$false} $token | Out-Null
                Write-Output "Đã ngừng bán gói kiểm thử: $($g.ten)"
            }
        }
        if($danhMuc.hoatDong) {
            Goi PUT "danh-muc/$id" @{ten=$danhMuc.ten;moTa=$danhMuc.moTa;loai=$danhMuc.loai;hoatDong=$false;anhId=$danhMuc.anhId} $token | Out-Null
            Write-Output "Đã ẩn danh mục kiểm thử: $($danhMuc.ten)"
        }
        $kiemTraDanhMuc=Goi GET "danh-muc?loai=DichVu&q=$([Uri]::EscapeDataString($danhMuc.ten))"
        $kiemTraGoi=Goi GET "goi-luot?danhMucId=$id"
        if(@($kiemTraDanhMuc.duLieu|Where-Object id -eq $id).Count -ne 0 -or @($kiemTraGoi.duLieu).Count -ne 0) {
            throw "Danh mục kiểm thử $id vẫn xuất hiện công khai sau khi dọn."
        }
        foreach($g in $cacGoi){Goi GET "goi-luot/$($g.id)" $null '' 404 | Out-Null}
    }
} finally {$http.Dispose()}
