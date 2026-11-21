param([string]$DiaChi='http://127.0.0.1:5080/api/v1')
# PowerShell 5.1 trở lên; chỉ chạy với cơ sở dữ liệu trình diễn vì tập lệnh tạo dữ liệu mẫu.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Net.Http
$http = [System.Net.Http.HttpClient]::new()
$http.Timeout = [TimeSpan]::FromSeconds(30)
$maLan=([guid]::NewGuid().ToString('N')).Substring(0,10)
$matKhauMau='Mau-'+[guid]::NewGuid().ToString('N')+'!'
function KiemTra($Dung,[string]$NoiDung){if(-not $Dung){throw "KHÔNG ĐẠT: $NoiDung"};Write-Output "ĐẠT: $NoiDung"}
function Goi([string]$Cach,[string]$DuongDan,$NoiDung=$null,[string]$Token='',[int]$Ma=200){
    $yeuCau=[System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::new($Cach),"$DiaChi/$DuongDan")
    $r=$null
    try {
        if($Token){$yeuCau.Headers.Authorization=[System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer',$Token)}
        if($null -ne $NoiDung){$yeuCau.Content=[System.Net.Http.StringContent]::new((ConvertTo-Json $NoiDung -Depth 20 -Compress),[Text.Encoding]::UTF8,'application/json')}
        $r=$http.SendAsync($yeuCau).GetAwaiter().GetResult()
        $noiDungTraVe=$r.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if([int]$r.StatusCode -ne $Ma){throw "API $DuongDan trả $([int]$r.StatusCode), mong đợi $Ma. Nội dung: $noiDungTraVe"}
        if($noiDungTraVe){
            $duLieuJson=$noiDungTraVe|ConvertFrom-Json
            if($duLieuJson -is [System.Array]) {
                foreach($muc in $duLieuJson){Write-Output $muc}
            } else {return $duLieuJson}
        }
    } finally {if($r){$r.Dispose()};$yeuCau.Dispose()}
}
function DangNhap([string]$Email,[string]$MatKhau){(Goi POST 'tai-khoan/dang-nhap' @{email=$Email;matKhau=$MatKhau}).maTruyCap}
try {
$sucKhoe=Goi GET 'suc-khoe'
KiemTra $sucKhoe.coSoDuLieu 'API kết nối được SQL Server'
$emailQt=Read-Host 'Email quản trị trình diễn'
$mkQt=Read-Host 'Mật khẩu quản trị' -AsSecureString
$tokenQt=DangNhap $emailQt ([System.Net.NetworkCredential]::new('',$mkQt).Password)
Goi GET 'suc-khoe' | Out-Null
Goi GET 'tai-khoan' $null '' 401 | Out-Null
$emailNtd="mau-ntd-$maLan@example.invalid"
$ntd=Goi POST 'tai-khoan/dang-ky' @{email=$emailNtd;hoTen="Nhà tuyển dụng MẪU $maLan";matKhau=$matKhauMau;loai='NhaTuyenDung'}
$tokenNtd=DangNhap $emailNtd $matKhauMau
Goi GET 'tai-khoan' $null $tokenNtd 403 | Out-Null
KiemTra $true 'Khách/Member không được xem danh sách quản trị'
$dn=Goi POST 'doanh-nghiep' @{ten="Doanh nghiệp MẪU $maLan";maSoThue='';diaChi='Địa chỉ dữ liệu mẫu';gioiThieu='Chỉ phục vụ kiểm thử'} $tokenNtd
Goi POST "doanh-nghiep/$($dn.id)/trang-thai" @{trangThai='DaDuyet';lyDo='Dữ liệu mẫu'} $tokenQt | Out-Null
Goi POST "doanh-nghiep/$($dn.id)/trang-thai" @{trangThai='DaDuyet';lyDo='Dữ liệu mẫu'} $tokenQt | Out-Null
$so=Goi GET 'so-luot' $null $tokenNtd
KiemTra ($so.soLuotConLai -eq 3) 'Duyệt hai lần chỉ cấp ba lượt miễn phí một lần'
$dm=Goi POST 'danh-muc' @{ten="Gói MẪU $maLan";moTa='Mẫu';loai='DichVu';hoatDong=$true;anhId=$null} $tokenQt
$thuMuc=Join-Path $PSScriptRoot "../work/kiem-thu-$maLan"
New-Item -ItemType Directory -Force -Path $thuMuc | Out-Null
$anh=Join-Path $thuMuc 'anh-mau.png'
[IO.File]::WriteAllBytes($anh,[Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jZrkAAAAASUVORK5CYII='))
$form=[System.Net.Http.MultipartFormDataContent]::new()
$yeuCauTep=[System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Post,"$DiaChi/tep")
$rTep=$null
try {
    $form.Add([System.Net.Http.StringContent]::new('Anh'),'loai')
    $anhGui=[System.Net.Http.ByteArrayContent]::new([IO.File]::ReadAllBytes($anh))
    $anhGui.Headers.ContentType=[System.Net.Http.Headers.MediaTypeHeaderValue]::new('image/png')
    $form.Add($anhGui,'tep','anh-mau.png')
    $yeuCauTep.Headers.Authorization=[System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer',$tokenQt)
    $yeuCauTep.Content=$form
    $rTep=$http.SendAsync($yeuCauTep).GetAwaiter().GetResult()
    $noiDungTep=$rTep.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    if([int]$rTep.StatusCode -ne 200){throw "Tải ảnh thất bại: $noiDungTep"}
    $tep=$noiDungTep|ConvertFrom-Json
} finally {if($rTep){$rTep.Dispose()};$yeuCauTep.Dispose();$form.Dispose()}
$g1=Goi POST 'goi-luot' @{ten="Cơ bản MẪU $maLan";moTa='Mẫu';danhMucId=$dm.id;anhId=$tep.id;soLuot=1;gia=20000;dangBan=$true} $tokenQt
$g5=Goi POST 'goi-luot' @{ten="Tiết kiệm MẪU $maLan";moTa='Mẫu';danhMucId=$dm.id;anhId=$tep.id;soLuot=5;gia=90000;dangBan=$true} $tokenQt
Goi DELETE "danh-muc/$($dm.id)" $null $tokenQt 409 | Out-Null
Goi PUT 'gio-hang' @{goiLuotId=$g1.id;soLuong=0;giaDaXem=20000} $tokenNtd 400 | Out-Null
Goi PUT 'gio-hang' @{goiLuotId=$g1.id;soLuong=3;giaDaXem=20000} $tokenNtd | Out-Null
Goi PUT 'gio-hang' @{goiLuotId=$g5.id;soLuong=2;giaDaXem=90000} $tokenNtd | Out-Null
$gio=@(Goi GET 'gio-hang' $null $tokenNtd)
KiemTra (($gio|Measure-Object -Property soLuong -Sum).Sum -eq 5) 'Giỏ có năm gói'
$khoa=[guid]::NewGuid().ToString()
$don=Goi POST 'don-hang' @{khoaLap=$khoa} $tokenNtd
$donLap=Goi POST 'don-hang' @{khoaLap=$khoa} $tokenNtd
KiemTra ($don.id -eq $donLap.id) 'Gửi lại cùng khóa không tạo đơn mới'
KiemTra ($don.tongTien -eq 240000 -and $don.tongLuot -eq 13) 'Đơn lưu đúng 240.000đ và 13 lượt'
Goi POST "don-hang/$($don.id)/trang-thai" @{trangThai='DaThanhToan'} $tokenNtd 403 | Out-Null
Goi POST "don-hang/$($don.id)/trang-thai" @{trangThai='DaThanhToan'} $tokenQt | Out-Null
Goi POST "don-hang/$($don.id)/trang-thai" @{trangThai='DaThanhToan'} $tokenQt | Out-Null
$so=Goi GET 'so-luot' $null $tokenNtd
KiemTra ($so.soLuotConLai -eq 16) 'Xác nhận hai lần chỉ cộng 13 lượt một lần'
Goi DELETE "goi-luot/$($g1.id)" $null $tokenQt 409 | Out-Null
Goi PUT "goi-luot/$($g1.id)" @{ten=$g1.ten;moTa='Mẫu';danhMucId=$dm.id;anhId=$tep.id;soLuot=1;gia=25000;dangBan=$true} $tokenQt | Out-Null
$cu=Goi GET "don-hang/$($don.id)" $null $tokenNtd
KiemTra ($cu.tongTien -eq 240000 -and ($cu.chiTiet|Where-Object goiLuotId -eq $g1.id).donGia -eq 20000) 'Đổi giá gói không thay giá đơn cũ'
Write-Output "Hoàn tất các ca kiểm thử API cơ bản. Dữ liệu MẪU có mã $maLan được giữ lại để đối chiếu. Cần kiểm thử Android, CV, trạng thái và đồng thời riêng."
} finally { $http.Dispose() }
