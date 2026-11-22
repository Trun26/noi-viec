param([string]$DiaChi='http://127.0.0.1:5080/api/v1')
# Chạy với API/SQL Server trình diễn và tài khoản quản trị.
# Tạo dữ liệu có mã riêng cho từng lần chạy; không xóa hồ sơ/lịch sử để giữ dấu vết nghiệm thu.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Net.Http
$http=[System.Net.Http.HttpClient]::new()
$http.Timeout=[TimeSpan]::FromSeconds(30)
$maLan=([guid]::NewGuid().ToString('N')).Substring(0,10)
$matKhauMau='Mau-'+[guid]::NewGuid().ToString('N')+'!'

function KiemTra($Dung,[string]$NoiDung) {
    if(-not $Dung){throw "KHÔNG ĐẠT: $NoiDung"}
    Write-Output "ĐẠT: $NoiDung"
}
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
function TaiCv([string]$Token,[string]$Ten) {
    $noiDung=[System.Text.Encoding]::ASCII.GetBytes("%PDF-1.4`n1 0 obj`n<<>>`nendobj`n%%EOF`n")
    $form=[System.Net.Http.MultipartFormDataContent]::new()
    $yeuCau=[System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Post,"$DiaChi/tep")
    $phanHoi=$null
    try {
        $form.Add([System.Net.Http.StringContent]::new('CV'),'loai')
        $tep=[System.Net.Http.ByteArrayContent]::new($noiDung)
        $tep.Headers.ContentType=[System.Net.Http.Headers.MediaTypeHeaderValue]::new('application/pdf')
        $form.Add($tep,'tep',"$Ten.pdf")
        $yeuCau.Headers.Authorization=[System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer',$Token)
        $yeuCau.Content=$form
        $phanHoi=$http.SendAsync($yeuCau).GetAwaiter().GetResult()
        $vanBan=$phanHoi.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if([int]$phanHoi.StatusCode -ne 200){throw "Tải CV thất bại: $vanBan"}
        return ($vanBan|ConvertFrom-Json)
    } finally {if($phanHoi){$phanHoi.Dispose()};$yeuCau.Dispose();$form.Dispose()}
}
function HoSoThongBao($Token,[string]$HoSoId) {
    $tb=Goi GET 'thong-bao' $null $Token
    return @($tb.duLieu|Where-Object { $_.duongDan -eq "ho-so/$HoSoId" })
}
try {
    $sucKhoe=Goi GET 'suc-khoe'
    KiemTra $sucKhoe.coSoDuLieu 'API truy cập được cơ sở dữ liệu'
    $emailQt=Read-Host 'Email quản trị trình diễn'
    $mkQt=Read-Host 'Mật khẩu quản trị' -AsSecureString
    $tokenQt=DangNhap $emailQt ([System.Net.NetworkCredential]::new('',$mkQt).Password)
    Goi GET 'tai-khoan' $null '' 401 | Out-Null

    $emailNtd="mau-ntd-$maLan@example.invalid"
    $emailNtdKhac="mau-ntd-khac-$maLan@example.invalid"
    $emailUv1="mau-uv-1-$maLan@example.invalid"
    $emailUv2="mau-uv-2-$maLan@example.invalid"
    foreach($m in @(@{email=$emailNtd;hoTen="Nhà tuyển dụng MẪU $maLan";matKhau=$matKhauMau;loai='NhaTuyenDung'},@{email=$emailNtdKhac;hoTen="Nhà tuyển dụng khác MẪU $maLan";matKhau=$matKhauMau;loai='NhaTuyenDung'},@{email=$emailUv1;hoTen="Ứng viên 1 MẪU $maLan";matKhau=$matKhauMau;loai='UngVien'},@{email=$emailUv2;hoTen="Ứng viên 2 MẪU $maLan";matKhau=$matKhauMau;loai='UngVien'})) {
        Goi POST 'tai-khoan/dang-ky' $m | Out-Null
    }
    $tokenNtd=DangNhap $emailNtd $matKhauMau
    $tokenNtdKhac=DangNhap $emailNtdKhac $matKhauMau
    $tokenUv1=DangNhap $emailUv1 $matKhauMau
    $tokenUv2=DangNhap $emailUv2 $matKhauMau
    Goi GET 'tai-khoan' $null $tokenNtd 403 | Out-Null
    KiemTra $true 'Tài khoản nhà tuyển dụng không có quyền quản trị'

    $dn=Goi POST 'doanh-nghiep' @{ten="Doanh nghiệp tuyển dụng MẪU $maLan";maSoThue='';diaChi='Dữ liệu trình diễn';gioiThieu='Kiểm thử luồng tuyển dụng'} $tokenNtd
    $dnKhac=Goi POST 'doanh-nghiep' @{ten="Doanh nghiệp khác MẪU $maLan";maSoThue='';diaChi='Dữ liệu trình diễn';gioiThieu='Kiểm thử phân quyền'} $tokenNtdKhac
    Goi POST "doanh-nghiep/$($dn.id)/trang-thai" @{trangThai='DaDuyet';lyDo=''} $tokenQt | Out-Null
    Goi POST "doanh-nghiep/$($dnKhac.id)/trang-thai" @{trangThai='DaDuyet';lyDo=''} $tokenQt | Out-Null
    $nganh=Goi GET 'danh-muc?loai=NganhNghe'
    $nganhId=@($nganh.duLieu|Where-Object hoatDong|Select-Object -First 1).id
    KiemTra ($null -ne $nganhId) 'Có ngành nghề đang hoạt động để tạo tin mẫu'
    $hanNhan=[DateTime]::UtcNow.AddDays(30).ToString('o')
    $tin=Goi POST 'tin-tuyen-dung' @{tieuDe="Nhân viên kiểm thử MẪU $maLan";nganhId=$nganhId;diaDiem='TP. Hồ Chí Minh';hinhThuc='ToanThoiGian';kinhNghiem='Chưa có kinh nghiệm';trinhDo='Không yêu cầu';moTa='Tin dùng kiểm thử, không liên hệ ứng viên thật.';yeuCau='';quyenLoi='';soNguoi=2;luongMin=$null;luongMax=$null;hanNhan=$hanNhan} $tokenNtd
    Goi POST "tin-tuyen-dung/$($tin.id)/trang-thai" @{trangThai='ChoDuyet';lyDo=''} $tokenNtd | Out-Null
    Goi POST "tin-tuyen-dung/$($tin.id)/trang-thai" @{trangThai='DangTuyen';lyDo=''} $tokenQt | Out-Null

    $cvXoa=TaiCv $tokenUv1 "cv-xoa-$maLan"
    $cv1=TaiCv $tokenUv1 "cv-ung-vien-1-$maLan"
    $cv2=TaiCv $tokenUv2 "cv-ung-vien-2-$maLan"
    $danhSachCv=Goi GET 'tep' $null $tokenUv1
    KiemTra (@($danhSachCv|Where-Object id -eq $cv1.id).Count -eq 1) 'Ứng viên xem được CV của mình'
    Goi DELETE "tep/$($cvXoa.id)" $null $tokenUv1 | Out-Null
    Goi GET "tep/$($cvXoa.id)" $null $tokenUv1 404 | Out-Null
    Goi GET "tep/$($cv1.id)" $null $tokenUv2 403 | Out-Null
    KiemTra $true 'CV độc lập xóa được và ứng viên khác không đọc được CV riêng'

    $hs1=Goi POST "tin-tuyen-dung/$($tin.id)/ung-tuyen" @{cvId=$cv1.id;thuGioiThieu='Hồ sơ thử nghiệm nhánh tuyển.'} $tokenUv1
    $hs2=Goi POST "tin-tuyen-dung/$($tin.id)/ung-tuyen" @{cvId=$cv2.id;thuGioiThieu='Hồ sơ thử nghiệm nhánh từ chối.'} $tokenUv2
    KiemTra ($hs1.trangThai -eq 'DaGui' -and $hs2.trangThai -eq 'DaGui') 'Hai ứng viên nộp hồ sơ với trạng thái ban đầu Đã gửi'
    Goi POST "tin-tuyen-dung/$($tin.id)/ung-tuyen" @{cvId=$cv1.id;thuGioiThieu='Nộp lặp'} $tokenUv1 409 | Out-Null
    Goi POST "ho-so/$($hs1.id)/trang-thai" @{trangThai='DangXemXet';ghiChu='';gioPhongVan=$null;hinhThuc=$null;diaDiem=$null} $tokenUv1 404 | Out-Null
    Goi GET "ho-so/$($hs1.id)" $null $tokenUv2 404 | Out-Null
    Goi GET "tep/$($cv1.id)" $null $tokenNtdKhac 403 | Out-Null
    Goi GET "ho-so/$($hs1.id)" $null $tokenNtdKhac 404 | Out-Null
    Goi POST "ho-so/$($hs1.id)/trang-thai" @{trangThai='DangXemXet';ghiChu='';gioPhongVan=$null;hinhThuc=$null;diaDiem=$null} $tokenNtdKhac 404 | Out-Null
    KiemTra $true 'Chặn ứng viên sửa trạng thái và chặn doanh nghiệp khác xem/xét hồ sơ hoặc CV'
    Goi DELETE "tep/$($cv1.id)" $null $tokenUv1 409 | Out-Null
    KiemTra $true 'Không xóa CV đang được hồ sơ ứng tuyển tham chiếu'

    $tbNtd=Goi GET 'thong-bao' $null $tokenNtd
    KiemTra (@($tbNtd.duLieu|Where-Object { $_.duongDan -eq "ho-so/$($hs1.id)" }).Count -ge 1) 'Doanh nghiệp nhận thông báo khi có hồ sơ mới'
    $tbUv=HoSoThongBao $tokenUv1 $hs1.id
    KiemTra ($tbUv.Count -ge 1 -and -not $tbUv[0].daDoc) 'Ứng viên nhận thông báo trạng thái chưa đọc sau khi nộp hồ sơ'
    Goi PUT "thong-bao/$($tbUv[0].id)/da-doc" $null $tokenUv2 404 | Out-Null
    $tbUv=Goi PUT "thong-bao/$($tbUv[0].id)/da-doc" $null $tokenUv1
    KiemTra $tbUv.daDoc 'Chủ thông báo đánh dấu đã đọc thành công'

    Goi POST "ho-so/$($hs1.id)/trang-thai" @{trangThai='DangXemXet';ghiChu='Đang đánh giá';gioPhongVan=$null;hinhThuc=$null;diaDiem=$null} $tokenNtd | Out-Null
    Goi POST "ho-so/$($hs1.id)/trang-thai" @{trangThai='MoiPhongVan';ghiChu='Mời trao đổi';gioPhongVan=[DateTime]::UtcNow.AddDays(2).ToString('o');hinhThuc='TrucTuyen';diaDiem='Liên kết họp thử'} $tokenNtd | Out-Null
    $chiTiet=Goi GET "ho-so/$($hs1.id)" $null $tokenUv1
    KiemTra ($chiTiet.hoSo.trangThai -eq 'MoiPhongVan' -and $chiTiet.hoSo.phongVanJson) 'Lời mời phỏng vấn có lịch tương lai và thông tin hình thức/địa điểm'
    Goi POST "ho-so/$($hs1.id)/trang-thai" @{trangThai='DaTuyen';ghiChu='Đạt thử nghiệm';gioPhongVan=$null;hinhThuc=$null;diaDiem=$null} $tokenNtd | Out-Null
    Goi POST "ho-so/$($hs2.id)/trang-thai" @{trangThai='TuChoi';ghiChu='Không phù hợp trong kịch bản mẫu';gioPhongVan=$null;hinhThuc=$null;diaDiem=$null} $tokenNtd | Out-Null
    $cuoi1=Goi GET "ho-so/$($hs1.id)" $null $tokenUv1
    $cuoi2=Goi GET "ho-so/$($hs2.id)" $null $tokenUv2
    KiemTra ($cuoi1.hoSo.trangThai -eq 'DaTuyen' -and @($cuoi1.lichSu).Count -eq 4) 'Nhánh xét duyệt → phỏng vấn → tuyển có đủ bốn mốc lịch sử'
    KiemTra ($cuoi2.hoSo.trangThai -eq 'TuChoi' -and @($cuoi2.lichSu).Count -eq 2) 'Nhánh từ chối có lịch sử nộp và từ chối'
    KiemTra ((HoSoThongBao $tokenUv1 $hs1.id).Count -ge 1 -and (HoSoThongBao $tokenUv2 $hs2.id).Count -ge 1) 'Ứng viên nhận thông báo sau các lần đổi trạng thái cuối'
    Write-Output "Mã chạy nghiệm thu: $maLan"
    Write-Output "Tin mẫu: $($tin.id); hồ sơ tuyển: $($hs1.id); hồ sơ từ chối: $($hs2.id)"
    Write-Output 'Dữ liệu được giữ lại trên DB trình diễn để đối chiếu; các email example.invalid không nhận thư thật.'
} finally {$http.Dispose()}
