namespace MayChu.NghiepVu;

public static class QuyTacHoSo
{
    public static bool ChoPhep(string cu, string moi) => cu switch
    {
        "DaGui" => moi is "DangXemXet" or "MoiPhongVan" or "TuChoi" or "DaRut",
        "DangXemXet" => moi is "MoiPhongVan" or "TuChoi" or "DaRut",
        "MoiPhongVan" => moi is "DaTuyen" or "TuChoi" or "DaRut",
        _ => false
    };
}
