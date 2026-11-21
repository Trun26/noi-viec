param([string]$DiaChi='http://127.0.0.1:5080/api/v1')
# PowerShell 5.1 trở lên; chỉ chạy với cơ sở dữ liệu trình diễn vì tập lệnh tạo dữ liệu mẫu.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Net.Http
$http = [System.Net.Http.HttpClient]::new()
$http.Timeout = [TimeSpan]::FromSeconds(30)
$maLan=([guid]::NewGuid().ToString('N')).Substring(0,10)
$matKhauMau='Mau-'+[guid]::NewGuid().ToString('N')+'!'
$tinDongThoi=[System.Collections.ArrayList]::new()
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
function GoiDongThoi($DuongDan,$NoiDung,[string]$Token,[int]$SoYeuCau=8){
    $yeuCaus=[System.Collections.ArrayList]::new()
    $tacVu=[System.Collections.Generic.List[System.Threading.Tasks.Task[System.Net.Http.HttpResponseMessage]]]::new()
    $phanHoi=@()
    try {
        for($i=0;$i -lt $SoYeuCau;$i++){
            $dd=if($DuongDan -is [array]){[string]$DuongDan[$i]}else{$DuongDan}
            $yeuCau=[System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Post,"$DiaChi/$dd")
            $yeuCau.Headers.Authorization=[System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer',$Token)
            $yeuCau.Content=[System.Net.Http.StringContent]::new((ConvertTo-Json $NoiDung -Depth 20 -Compress),[Text.Encoding]::UTF8,'application/json')
            [void]$yeuCaus.Add($yeuCau)
            $tacVu.Add($http.SendAsync($yeuCau))
        }
        [System.Threading.Tasks.Task]::WhenAll([System.Threading.Tasks.Task[]]$tacVu.ToArray()).GetAwaiter().GetResult() | Out-Null
        for($i=0;$i -lt $tacVu.Count;$i++){
            $r=$tacVu[$i].Result
            $phanHoi+=@([pscustomobject]@{ma=[int]$r.StatusCode;duLieu=($r.Content.ReadAsStringAsync().GetAwaiter().GetResult()|ConvertFrom-Json)})
        }
        return ,$phanHoi
    } finally {
        foreach($y in $yeuCaus){$y.Dispose()}
        foreach($t in $tacVu){if($t.Status -eq [System.Threading.Tasks.TaskStatus]::RanToCompletion -and $null -ne $t.Result){$t.Result.Dispose()}}
    }
}
function DangNhap([string]$Email,[string]$MatKhau){(Goi POST 'tai-khoan/dang-nhap' @{email=$Email;matKhau=$MatKhau}).maTruyCap}
function NgungBanGoi([string]$GoiId,[string]$DanhMucId,[string]$Token){
    $cacGoiQuanTri=Goi GET "goi-luot?quanLy=true&danhMucId=$DanhMucId&kichThuoc=50" $null $Token
    $goiHienTai=@($cacGoiQuanTri.duLieu|Where-Object id -eq $GoiId)|Select-Object -First 1
    if($null -eq $goiHienTai){throw "Không tìm thấy gói kiểm thử $GoiId trong danh sách quản trị."}
    Goi PUT "goi-luot/$GoiId" @{ten=$goiHienTai.ten;moTa=$goiHienTai.moTa;danhMucId=$goiHienTai.danhMucId;anhId=$goiHienTai.anhId;soLuot=$goiHienTai.soLuot;gia=$goiHienTai.gia;dangBan=$false} $Token | Out-Null
}
try {
$sucKhoe=Goi GET 'suc-khoe'
KiemTra $sucKhoe.coSoDuLieu 'API kết nối được SQL Server'
$emailQt=Read-Host 'Email quản trị trình diễn'
$mkQt=Read-Host 'Mật khẩu quản trị' -AsSecureString
$tokenQt=DangNhap $emailQt ([System.Net.NetworkCredential]::new('',$mkQt).Password)
Goi GET 'suc-khoe' | Out-Null
Goi GET 'tai-khoan' $null '' 401 | Out-Null
Goi GET 'danh-muc?loai=DichVu&quanLy=true' $null '' 401 | Out-Null
$emailNtd="mau-ntd-$maLan@example.invalid"
$ntd=Goi POST 'tai-khoan/dang-ky' @{email=$emailNtd;hoTen="Nhà tuyển dụng MẪU $maLan";matKhau=$matKhauMau;loai='NhaTuyenDung'}
$tokenNtd=DangNhap $emailNtd $matKhauMau
Goi GET 'tai-khoan' $null $tokenNtd 403 | Out-Null
Goi GET 'danh-muc?loai=DichVu&quanLy=true' $null $tokenNtd 403 | Out-Null
KiemTra $true 'Khách/Member không được xem danh sách quản trị'
$dn=Goi POST 'doanh-nghiep' @{ten="Doanh nghiệp MẪU $maLan";maSoThue='';diaChi='Địa chỉ dữ liệu mẫu';gioiThieu='Chỉ phục vụ kiểm thử'} $tokenNtd
Goi POST "doanh-nghiep/$($dn.id)/trang-thai" @{trangThai='DaDuyet';lyDo='Dữ liệu mẫu'} $tokenQt | Out-Null
Goi POST "doanh-nghiep/$($dn.id)/trang-thai" @{trangThai='DaDuyet';lyDo='Dữ liệu mẫu'} $tokenQt | Out-Null
$so=Goi GET 'so-luot' $null $tokenNtd
KiemTra ($so.soLuotConLai -eq 3) 'Duyệt hai lần chỉ cấp ba lượt miễn phí một lần'

    $nganh=Goi GET 'danh-muc?loai=NganhNghe'
    $nganhId=@($nganh.duLieu|Where-Object hoatDong|Select-Object -First 1).id
    KiemTra ($null -ne $nganhId) 'Có ngành nghề đang hoạt động để kiểm thử lượt đồng thời'
    $hanNhan=[DateTime]::UtcNow.AddDays(30).ToString('o')
    $cacTin=@()
    for($i=1;$i -le 4;$i++){
        $t=Goi POST 'tin-tuyen-dung' @{tieuDe="Tin đồng thời MẪU $maLan $i";nganhId=$nganhId;diaDiem='TP. Hồ Chí Minh';hinhThuc='ToanThoiGian';kinhNghiem='Không yêu cầu';trinhDo='Không yêu cầu';moTa='Dữ liệu thử giao dịch đồng thời.';yeuCau='';quyenLoi='';soNguoi=1;luongMin=$null;luongMax=$null;hanNhan=$hanNhan} $tokenNtd
        $cacTin+=@($t)
        [void]$tinDongThoi.Add($t)
    }
    $duongDanGiu=@($cacTin|ForEach-Object {"tin-tuyen-dung/$($_.id)/trang-thai"})
    $ketQuaGiuLuot=GoiDongThoi $duongDanGiu @{trangThai='ChoDuyet';lyDo=''} $tokenNtd $duongDanGiu.Count
    $loiGiu=@($ketQuaGiuLuot|Where-Object { $_.ma -notin @(200,409) })
    KiemTra ($loiGiu.Count -eq 0) 'Bốn yêu cầu giữ lượt đồng thời không phát sinh lỗi ngoài dự kiến'
    $daGiu=[System.Collections.ArrayList]::new()
    $choThuLai=[System.Collections.ArrayList]::new()
    for($i=0;$i -lt $ketQuaGiuLuot.Count;$i++){
        if($ketQuaGiuLuot[$i].ma -eq 200){[void]$daGiu.Add([string]$cacTin[$i].id)}
        elseif($ketQuaGiuLuot[$i].ma -eq 409){[void]$choThuLai.Add([string]$cacTin[$i].id)}
    }
    while($choThuLai.Count -gt 0){
        $so=Goi GET 'so-luot' $null $tokenNtd
        if($so.soLuotConLai -le 0){break}
        $id=$choThuLai[0]
        Goi POST "tin-tuyen-dung/$id/trang-thai" @{trangThai='ChoDuyet';lyDo=''} $tokenNtd | Out-Null
        [void]$daGiu.Add($id)
        [void]$choThuLai.RemoveAt(0)
    }
    $so=Goi GET 'so-luot' $null $tokenNtd
    KiemTra ($daGiu.Count -eq 3 -and $choThuLai.Count -eq 1 -and $so.soLuotConLai -eq 0 -and $so.soLuotDangGiu -eq 3 -and $so.soLuotDaDung -eq 0) 'Bốn lượt đăng cạnh tranh chỉ giữ đúng ba lượt, không âm số dư'
    $duongDanTra=@($daGiu|ForEach-Object {"tin-tuyen-dung/$_/trang-thai"})
    $ketQuaTra=GoiDongThoi $duongDanTra @{trangThai='BiTuChoi';lyDo="Hoàn trả lượt sau kiểm thử $maLan"} $tokenQt $duongDanTra.Count
    $loiTra=@($ketQuaTra|Where-Object { $_.ma -notin @(200,409) })
    KiemTra ($loiTra.Count -eq 0) 'Ba yêu cầu hoàn lượt đồng thời không phát sinh lỗi ngoài dự kiến'
    foreach($id in $daGiu){
        $trangThaiTin=Goi GET "tin-tuyen-dung/$id" $null $tokenQt
        if($trangThaiTin.trangThai -eq 'ChoDuyet'){
            Goi POST "tin-tuyen-dung/$id/trang-thai" @{trangThai='BiTuChoi';lyDo="Hoàn trả lượt sau kiểm thử $maLan"} $tokenQt | Out-Null
            $trangThaiTin=Goi GET "tin-tuyen-dung/$id" $null $tokenQt
        }
        KiemTra ($trangThaiTin.trangThai -eq 'BiTuChoi') 'Tin kiểm thử được hoàn lượt đúng một lần sau cạnh tranh đồng thời'
    }
    $so=Goi GET 'so-luot' $null $tokenNtd
    KiemTra ($so.soLuotConLai -eq 3 -and $so.soLuotDangGiu -eq 0 -and $so.soLuotDaDung -eq 0) 'Hoàn ba tin đồng thời khôi phục đúng ba lượt khả dụng'
$dm=Goi POST 'danh-muc' @{ten="Gói MẪU $maLan";moTa='Mẫu';loai='DichVu';hoatDong=$true;anhId=$null} $tokenQt
$queryDanhMuc=[Uri]::EscapeDataString($dm.ten)
$danhMucMauDangHoatDong=Goi GET "danh-muc?loai=DichVu&q=$queryDanhMuc"
KiemTra (@($danhMucMauDangHoatDong.duLieu).Count -eq 0) 'Danh mục có mã kiểm thử không xuất hiện công khai kể cả khi còn hoạt động'
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
$goiMauDangHoatDong=Goi GET "goi-luot?danhMucId=$($dm.id)"
KiemTra (@($goiMauDangHoatDong.duLieu).Count -eq 0) 'Gói thuộc danh mục kiểm thử không xuất hiện công khai kể cả khi đang bán'
Goi GET "goi-luot/$($g1.id)" $null '' 404 | Out-Null
KiemTra $true 'Không mở được trực tiếp gói kiểm thử đang bán bằng đường dẫn công khai'
KiemTra ((Goi GET "goi-luot?quanLy=true&danhMucId=$($dm.id)&kichThuoc=50" $null $tokenQt).duLieu.Count -eq 2) 'Quản trị vẫn xem được hai gói kiểm thử đang hoạt động'
Goi DELETE "danh-muc/$($dm.id)" $null $tokenQt 409 | Out-Null
Goi PUT 'gio-hang' @{goiLuotId=$g1.id;soLuong=0;giaDaXem=20000} $tokenNtd 400 | Out-Null
Goi PUT 'gio-hang' @{goiLuotId=$g1.id;soLuong=3;giaDaXem=20000} $tokenNtd | Out-Null
Goi PUT 'gio-hang' @{goiLuotId=$g5.id;soLuong=2;giaDaXem=90000} $tokenNtd | Out-Null
$gio=@(Goi GET 'gio-hang' $null $tokenNtd)
KiemTra (($gio|Measure-Object -Property soLuong -Sum).Sum -eq 5) 'Giỏ có năm gói'
$khoa=[guid]::NewGuid().ToString()
$ketQuaDatDon=GoiDongThoi 'don-hang' @{khoaLap=$khoa} $tokenNtd 8
$loiDatDon=@($ketQuaDatDon|Where-Object { $_.ma -notin @(200,409) })
KiemTra ($loiDatDon.Count -eq 0) 'Tám yêu cầu đặt cùng khóa chỉ trả thành công hoặc xung đột có thể thử lại'
$donThanhCong=@($ketQuaDatDon|Where-Object { $_.ma -eq 200 -and $_.duLieu.id }|Select-Object -First 1)
KiemTra ($donThanhCong.Count -eq 1) 'Có ít nhất một yêu cầu đồng thời tạo/trả đơn'
$don=$donThanhCong[0].duLieu
foreach($xungDot in @($ketQuaDatDon|Where-Object ma -eq 409)){
    $thuLai=Goi POST 'don-hang' @{khoaLap=$khoa} $tokenNtd
    KiemTra ($thuLai.id -eq $don.id) 'Thử lại yêu cầu đặt đơn xung đột nhận đúng đơn đã tạo'
}
$donLap=Goi POST 'don-hang' @{khoaLap=$khoa} $tokenNtd
KiemTra ($don.id -eq $donLap.id) 'Tám yêu cầu đồng thời cùng khóa không tạo đơn trùng'
KiemTra ($don.tongTien -eq 240000 -and $don.tongLuot -eq 13) 'Đơn lưu đúng 240.000đ và 13 lượt'
Goi POST "don-hang/$($don.id)/trang-thai" @{trangThai='DaThanhToan'} $tokenNtd 403 | Out-Null
$ketQuaXacNhan=GoiDongThoi "don-hang/$($don.id)/trang-thai" @{trangThai='DaThanhToan'} $tokenQt 8
$loiXacNhan=@($ketQuaXacNhan|Where-Object { $_.ma -notin @(200,409) })
KiemTra ($loiXacNhan.Count -eq 0) 'Tám yêu cầu xác nhận đơn đồng thời chỉ trả thành công hoặc xung đột có thể thử lại'
$xacNhanThanhCong=@($ketQuaXacNhan|Where-Object ma -eq 200)
KiemTra ($xacNhanThanhCong.Count -ge 1) 'Có yêu cầu đồng thời xác nhận đơn thành công'
foreach($xungDot in @($ketQuaXacNhan|Where-Object ma -eq 409)){
    Goi POST "don-hang/$($don.id)/trang-thai" @{trangThai='DaThanhToan'} $tokenQt | Out-Null
}
$so=Goi GET 'so-luot' $null $tokenNtd
KiemTra ($so.soLuotConLai -eq 16) 'Xác nhận đơn đồng thời chỉ cộng đúng 13 lượt một lần'
Goi DELETE "goi-luot/$($g1.id)" $null $tokenQt 409 | Out-Null
Goi PUT "goi-luot/$($g1.id)" @{ten=$g1.ten;moTa='Mẫu';danhMucId=$dm.id;anhId=$tep.id;soLuot=1;gia=25000;dangBan=$true} $tokenQt | Out-Null
$cu=Goi GET "don-hang/$($don.id)" $null $tokenNtd
KiemTra ($cu.tongTien -eq 240000 -and ($cu.chiTiet|Where-Object goiLuotId -eq $g1.id).donGia -eq 20000) 'Đổi giá gói không thay giá đơn cũ'
NgungBanGoi $g1.id $dm.id $tokenQt
$goiConBan=Goi GET "goi-luot?danhMucId=$($dm.id)"
KiemTra ($goiConBan.duLieu.Count -eq 1 -and $goiConBan.duLieu[0].id -eq $g5.id) 'Gói ngừng bán biến mất khỏi danh sách dù danh mục vẫn hoạt động'
Goi GET "goi-luot/$($g1.id)" $null '' 404 | Out-Null
NgungBanGoi $g5.id $dm.id $tokenQt
Goi PUT "danh-muc/$($dm.id)" @{ten=$dm.ten;moTa=$dm.moTa;loai=$dm.loai;hoatDong=$false;anhId=$dm.anhId} $tokenQt | Out-Null
$danhMucCongKhai=Goi GET "danh-muc?loai=DichVu&q=$queryDanhMuc"
$danhMucQuanTri=Goi GET "danh-muc?loai=DichVu&q=$queryDanhMuc&quanLy=true" $null $tokenQt
$goiCongKhai=Goi GET "goi-luot?danhMucId=$($dm.id)"
KiemTra ($danhMucCongKhai.duLieu.Count -eq 0 -and $goiCongKhai.duLieu.Count -eq 0) 'Danh mục và gói kiểm thử đã ẩn khỏi danh sách công khai'
KiemTra (($danhMucQuanTri.duLieu|Where-Object id -eq $dm.id).Count -eq 1) 'Quản trị vẫn xem được danh mục kiểm thử đã ẩn'
Goi GET "goi-luot/$($g1.id)" $null '' 404 | Out-Null
KiemTra $true 'Gói ngừng bán không mở được bằng đường dẫn chi tiết công khai'
$goiQuanTri=Goi GET "goi-luot/$($g1.id)?quanLy=true" $null $tokenQt
KiemTra ($goiQuanTri.id -eq $g1.id) 'Quản trị vẫn xem được chi tiết gói đã ẩn'
Write-Output "Hoàn tất kiểm thử API cơ bản và đồng thời. Dữ liệu đơn hàng được giữ để đối chiếu; danh mục và gói kiểm thử có mã $maLan đã ngừng bán và ẩn khỏi ứng dụng. Cần chạy với API/SQL Server demo để xác minh thực tế."
} finally {
    try {
        if($tokenQt){
            foreach($t in $tinDongThoi){
                try {
                    $trangThaiTin=Goi GET "tin-tuyen-dung/$($t.id)" $null $tokenQt
                    if($trangThaiTin.trangThai -eq 'ChoDuyet'){
                        Goi POST "tin-tuyen-dung/$($t.id)/trang-thai" @{trangThai='BiTuChoi';lyDo="Dọn tin kiểm thử $maLan"} $tokenQt | Out-Null
                    }
                } catch { Write-Warning "Không thể hoàn lượt/dọn tin kiểm thử $($t.id): $($_.Exception.Message)" }
            }
        }
        if ($tokenQt -and $dm) {
            foreach ($goiMau in @($g1,$g5)) {
                if ($null -eq $goiMau) { continue }
                try {
                    NgungBanGoi $goiMau.id $dm.id $tokenQt
                } catch { Write-Warning "Không thể tự ẩn gói kiểm thử $($goiMau.id): $($_.Exception.Message)" }
            }
            try {
                Goi PUT "danh-muc/$($dm.id)" @{ten=$dm.ten;moTa=$dm.moTa;loai=$dm.loai;hoatDong=$false;anhId=$dm.anhId} $tokenQt | Out-Null
            } catch { Write-Warning "Không thể tự ẩn danh mục kiểm thử $($dm.id): $($_.Exception.Message)" }
        }
    } finally { $http.Dispose() }
}
