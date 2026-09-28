//
//  ILTempleUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILTempleUseCase {
    /// Trả về dữ liệu 1 chùa theo `templeID`. Nếu không tìm thấy, rơi về chùa Từ Quang — chùa mẫu
    /// dữ liệu đầy đủ nhất (khớp design handoff `s.tpId || 'tp-tuquang'`) — giữ màn luôn hiển thị
    /// được nội dung.
    func getInitialState(templeID: String) -> ILTempleEntity

    /// Theo dõi / bỏ theo dõi chùa — cần repository lưu danh sách chùa đang theo dõi (chưa build).
    func toggleFollow(templeID: String) async throws
}

final class ILTempleUseCaseImpl: ILTempleUseCase {

    // TODO: khi có API chùa thật, thay catalog mock dưới đây bằng dữ liệu từ networkService
    // (danh mục "Chùa Việt Nam" ở Trang chủ + hồ sơ đầy đủ của Trang chùa, xem README design
    // handoff — mục "Data cần API"). Nội dung này là DATA (tên, tiểu sử, giờ mở cửa, liên hệ...),
    // không phải UI copy nên để nguyên chuỗi tiếng Việt thay vì đưa qua `.localized` — khác với
    // nhãn UI (được `ILTempleViewModel` resolve từ key), giống cách `ILDeityUseCaseImpl` làm.
    // `name`/`place` của 8 chùa carousel + Từ Quang vẫn dùng lại key `home.temple.*` đã có — cùng
    // 1 nguồn dữ liệu với carousel Trang chủ và `ILFestivalsUseCase`.
    init() {}

    func getInitialState(templeID: String) -> ILTempleEntity {
        let catalog = Self.makeTempleCatalog()
        return catalog.first { $0.id == templeID } ?? catalog[0]
    }

    func toggleFollow(templeID: String) async throws {
        print("TODO: implement toggleFollow — repository call, not built by il-screen-builder")
    }

    // MARK: - Catalog

    /// 9 chùa khớp `Component.TEMPLE_INFO` trong design handoff — Từ Quang (giả lập đầy đủ) đứng
    /// đầu, 8 chùa còn lại khớp carousel "Chùa Việt Nam" ở Trang chủ.
    private static func makeTempleCatalog() -> [ILTempleEntity] {
        [
            ILTempleEntity(
                id: "tp-tuquang",
                name: "home.temple.tuquang.name".localized,
                aliases: ["Chùa Ông Quang"],
                latitude: 10.8030, longitude: 106.6960,
                street: "128 Nguyễn Văn Đậu", ward: "Phường 5", district: "Quận Bình Thạnh",
                province: "TP. Hồ Chí Minh", region: "Miền Nam", subRegion: "Đông Nam Bộ",
                sect: "Bắc tông",
                orgInfo: [
                    ILTempleOrgInfoEntity(id: "abbot", label: "Trụ trì", value: "Đại đức Thích Minh Đạo"),
                    ILTempleOrgInfoEntity(id: "founder", label: "Tổ khai sơn", value: "Hòa thượng Thích Huệ Quang"),
                    ILTempleOrgInfoEntity(id: "sangha", label: "Giáo hội", value: "GHPGVN TP. Hồ Chí Minh · Ban Trị sự Q. Bình Thạnh")
                ],
                era: "Năm 1938", rank: "Không xếp hạng",
                archStyle: "Kiểu chữ Tam", materials: "Gỗ căm xe, ngói âm dương, nền đá ong",
                highlights: [
                    "Chánh điện gỗ căm xe nguyên bản từ năm 1938",
                    "Vườn thiền và hồ sen trước tổ đường"
                ],
                bio: "Chùa Từ Quang được Hòa thượng Thích Huệ Quang khai sơn năm 1938, khi vùng Bình Thạnh còn là ruộng vườn ven kênh. Buổi đầu chỉ là một thảo am lợp lá; đến thập niên 1960, chư tăng và Phật tử cùng dựng lại chánh điện theo kiểu chữ Tam bằng gỗ căm xe. Trải qua nhiều lần trùng tu, chùa vẫn giữ nếp sinh hoạt giản dị: khóa tụng sáng, khóa thiền tối và lớp Phật pháp cho thiếu nhi vào Chủ Nhật. Hằng năm vào mùa Vu Lan, chùa tổ chức lễ cài hoa hồng và thắp đèn tri ân, thu hút đông đảo Phật tử trong vùng về tham dự.",
                regularHours: ILTempleOpeningHoursEntity(openMinute: 300, closeMinute: 1200),
                holidayHours: ILTempleOpeningHoursEntity(openMinute: 240, closeMinute: 1320),
                contacts: [
                    ILTempleContactEntity(id: "phone", label: "Hotline", rawValue: "028 3841 2256"),
                    ILTempleContactEntity(id: "fanpage", label: "Fanpage", rawValue: "facebook.com/chuatuquang"),
                    ILTempleContactEntity(id: "website", label: "Website", rawValue: "chuatuquang.vn"),
                    ILTempleContactEntity(id: "email", label: "Email", rawValue: "banhotri@chuatuquang.vn")
                ],
                amenities: [
                    ILTempleAmenityEntity(id: "car", label: "Bãi đỗ ô tô", value: "Có · sân trước, miễn phí"),
                    ILTempleAmenityEntity(id: "bike", label: "Giữ xe máy", value: "Có · miễn phí"),
                    ILTempleAmenityEntity(id: "veg", label: "Cơm chay", value: "Tùy hỷ · trưa Rằm & Mùng Một"),
                    ILTempleAmenityEntity(id: "books", label: "Kinh sách", value: "Có · kinh sách, chuỗi hạt"),
                    ILTempleAmenityEntity(id: "retreat", label: "Khóa tu", value: "Khóa tu một ngày hằng tháng · khóa tu mùa hè")
                ],
                visitRules: [
                    "Mặc áo tràng hoặc trang phục kín đáo; không mặc váy ngắn, quần short",
                    "Không chụp ảnh, quay phim trong chánh điện khi đang hành lễ",
                    "Giữ im lặng, tắt chuông điện thoại trong khóa tụng"
                ],
                hasUpcomingSchedule: true,
                sessions: Self.makeSessionCatalog(),
                updatedLabel: "09/2026"
            ),
            ILTempleEntity(
                id: "tp-motcot",
                name: "home.temple.motcot.name".localized,
                aliases: ["Diên Hựu tự", "Liên Hoa Đài"],
                latitude: 21.0359, longitude: 105.8336,
                street: "Phố Chùa Một Cột", ward: "Phường Đội Cấn", district: "Quận Ba Đình",
                province: "TP. Hà Nội", region: "Miền Bắc", subRegion: "Đồng bằng sông Hồng",
                sect: "Bắc tông",
                orgInfo: [
                    ILTempleOrgInfoEntity(id: "abbot", label: "Trụ trì", value: nil),
                    ILTempleOrgInfoEntity(id: "founder", label: "Tổ khai sơn", value: "Vua Lý Thái Tông"),
                    ILTempleOrgInfoEntity(id: "sangha", label: "Giáo hội", value: "GHPGVN TP. Hà Nội")
                ],
                era: "Năm 1049 · thời Lý", rank: "Di tích Quốc gia đặc biệt",
                archStyle: "Đài sen trên một cột đá", materials: "Gỗ, cột đá giữa hồ Linh Chiểu",
                highlights: [
                    "Điện thờ Quán Thế Âm đặt trên một cột đá, dáng như bông sen mọc giữa hồ",
                    "Một trong những biểu tượng kiến trúc lâu đời của Thăng Long – Hà Nội"
                ],
                bio: "Theo sử cũ, vua Lý Thái Tông mộng thấy Phật Bà Quán Âm ngồi trên tòa sen dắt vua lên đài. Tỉnh dậy, vua cho dựng một ngôi chùa có đài sen đặt trên một cột đá giữa hồ, theo đúng hình ảnh trong giấc mộng, đặt tên là Diên Hựu, với ý cầu cho vận nước dài lâu. Công trình trải qua nhiều lần trùng tu; năm 1954 đài chùa bị phá hủy và được dựng lại năm 1955 theo kiến trúc cũ. Dù kích thước khiêm tốn, chùa là biểu tượng văn hóa của Hà Nội và là nơi Phật tử thường về chiêm bái Đức Quán Thế Âm.",
                regularHours: ILTempleOpeningHoursEntity(openMinute: 420, closeMinute: 1080),
                holidayHours: ILTempleOpeningHoursEntity(openMinute: 360, closeMinute: 1140),
                contacts: [
                    ILTempleContactEntity(id: "phone", label: "Hotline", rawValue: nil),
                    ILTempleContactEntity(id: "fanpage", label: "Fanpage", rawValue: nil),
                    ILTempleContactEntity(id: "website", label: "Website", rawValue: nil),
                    ILTempleContactEntity(id: "email", label: "Email", rawValue: nil)
                ],
                amenities: [
                    ILTempleAmenityEntity(id: "car", label: "Bãi đỗ ô tô", value: "Không · gửi tại bãi quanh Lăng"),
                    ILTempleAmenityEntity(id: "bike", label: "Giữ xe máy", value: "Có · thu phí"),
                    ILTempleAmenityEntity(id: "veg", label: "Cơm chay", value: nil),
                    ILTempleAmenityEntity(id: "books", label: "Kinh sách", value: nil),
                    ILTempleAmenityEntity(id: "retreat", label: "Khóa tu", value: nil)
                ],
                visitRules: [
                    "Trang phục lịch sự, che vai và gối",
                    "Xếp hàng lên đài theo lối cầu thang, không chen lấn",
                    "Không đặt tiền lẻ lên tượng Phật; công đức vào hòm"
                ],
                hasUpcomingSchedule: false,
                sessions: [],
                updatedLabel: "09/2026"
            ),
            ILTempleEntity(
                id: "tp-tranquoc",
                name: "home.temple.tranquoc.name".localized,
                aliases: ["Khai Quốc tự", "An Quốc tự"],
                latitude: 21.0480, longitude: 105.8368,
                street: "Đường Thanh Niên", ward: "Phường Yên Phụ", district: "Quận Tây Hồ",
                province: "TP. Hà Nội", region: "Miền Bắc", subRegion: "Đồng bằng sông Hồng",
                sect: "Bắc tông",
                orgInfo: [
                    ILTempleOrgInfoEntity(id: "abbot", label: "Trụ trì", value: nil),
                    ILTempleOrgInfoEntity(id: "founder", label: "Tổ khai sơn", value: "Khởi dựng thời Lý Nam Đế"),
                    ILTempleOrgInfoEntity(id: "sangha", label: "Giáo hội", value: "GHPGVN TP. Hà Nội")
                ],
                era: "Thế kỷ 6", rank: "Di tích Quốc gia",
                archStyle: "Tiền đường – thiêu hương – thượng điện nối nhau", materials: "Gỗ, gạch nung, ngói mũi hài",
                highlights: [
                    "Bảo tháp Lục Độ Đài Sen 11 tầng dựng năm 1998",
                    "Cây bồ đề chiết từ cây gốc tại Bồ Đề Đạo Tràng, Ấn Độ"
                ],
                bio: "Chùa Trấn Quốc được xem là ngôi chùa cổ nhất Thăng Long, khởi dựng từ thời Tiền Lý bên bờ sông Hồng với tên Khai Quốc. Đầu thế kỷ 17, do bãi sông lở, chùa được dời vào bán đảo Kim Ngư trên Hồ Tây như ngày nay. Thời Lê, chùa đổi tên thành Trấn Quốc với mong ước giữ yên bờ cõi. Cảnh chùa nằm giữa mặt nước, cây cổ thụ và tháp gạch cao vút, tạo nên không gian thanh tịnh ngay giữa phố thị. Chùa là điểm chiêm bái quen thuộc của Phật tử và du khách mỗi dịp Rằm, mùng Một.",
                regularHours: ILTempleOpeningHoursEntity(openMinute: 480, closeMinute: 1110),
                holidayHours: ILTempleOpeningHoursEntity(openMinute: 360, closeMinute: 1170),
                contacts: [
                    ILTempleContactEntity(id: "phone", label: "Hotline", rawValue: nil),
                    ILTempleContactEntity(id: "fanpage", label: "Fanpage", rawValue: nil),
                    ILTempleContactEntity(id: "website", label: "Website", rawValue: nil),
                    ILTempleContactEntity(id: "email", label: "Email", rawValue: nil)
                ],
                amenities: [
                    ILTempleAmenityEntity(id: "car", label: "Bãi đỗ ô tô", value: "Không · dừng đỗ ven đường hạn chế"),
                    ILTempleAmenityEntity(id: "bike", label: "Giữ xe máy", value: "Có · thu phí"),
                    ILTempleAmenityEntity(id: "veg", label: "Cơm chay", value: nil),
                    ILTempleAmenityEntity(id: "books", label: "Kinh sách", value: "Có · quầy văn hóa phẩm"),
                    ILTempleAmenityEntity(id: "retreat", label: "Khóa tu", value: nil)
                ],
                visitRules: [
                    "Không mặc quần short, váy ngắn, áo hai dây",
                    "Không leo trèo hay chạm vào bảo tháp",
                    "Giữ trật tự, không gây ồn trong khuôn viên"
                ],
                hasUpcomingSchedule: false,
                sessions: [],
                updatedLabel: "09/2026"
            ),
            ILTempleEntity(
                id: "tp-huong",
                name: "home.temple.huong.name".localized,
                aliases: ["Chùa Hương Tích", "Hương Sơn"],
                latitude: 20.6167, longitude: 105.7472,
                street: "Khu di tích Hương Sơn", ward: "Xã Hương Sơn", district: "Huyện Mỹ Đức",
                province: "TP. Hà Nội", region: "Miền Bắc", subRegion: "Đồng bằng sông Hồng",
                sect: "Bắc tông",
                orgInfo: [
                    ILTempleOrgInfoEntity(id: "abbot", label: "Trụ trì", value: nil),
                    ILTempleOrgInfoEntity(id: "founder", label: "Tổ khai sơn", value: nil),
                    ILTempleOrgInfoEntity(id: "sangha", label: "Giáo hội", value: "GHPGVN TP. Hà Nội")
                ],
                era: "Thế kỷ 17", rank: "Di tích Quốc gia đặc biệt",
                archStyle: "Quần thể chùa trong hang động núi đá vôi", materials: "Đá, gỗ, nhũ đá tự nhiên",
                highlights: [
                    "Động Hương Tích — được chúa Trịnh Sâm khen là \u{201c}Nam thiên đệ nhất động\u{201d}",
                    "Đường thuyền dọc suối Yến vào chùa Thiên Trù"
                ],
                bio: "Chùa Hương là quần thể gồm nhiều chùa, đền và hang động nằm giữa núi rừng Hương Sơn, huyện Mỹ Đức. Trung tâm là động Hương Tích, nơi thờ Đức Quán Thế Âm, được chúa Trịnh Sâm đề tặng năm chữ \u{201c}Nam thiên đệ nhất động\u{201d}. Hành trình hành hương thường bắt đầu từ bến Yến, đi thuyền dọc dòng suối uốn quanh núi, rồi leo bộ hoặc đi cáp treo lên động. Lễ hội chùa Hương kéo dài từ tháng Giêng đến tháng Ba âm lịch, là một trong những mùa hành hương lớn nhất cả nước.",
                regularHours: ILTempleOpeningHoursEntity(openMinute: 360, closeMinute: 1080),
                holidayHours: ILTempleOpeningHoursEntity(openMinute: 300, closeMinute: 1080),
                contacts: [
                    ILTempleContactEntity(id: "phone", label: "Hotline", rawValue: nil),
                    ILTempleContactEntity(id: "fanpage", label: "Fanpage", rawValue: nil),
                    ILTempleContactEntity(id: "website", label: "Website", rawValue: nil),
                    ILTempleContactEntity(id: "email", label: "Email", rawValue: nil)
                ],
                amenities: [
                    ILTempleAmenityEntity(id: "car", label: "Bãi đỗ ô tô", value: "Có · bãi tại bến Yến, thu phí"),
                    ILTempleAmenityEntity(id: "bike", label: "Giữ xe máy", value: "Có · thu phí"),
                    ILTempleAmenityEntity(id: "veg", label: "Cơm chay", value: "Có · quán chay dọc đường lên động"),
                    ILTempleAmenityEntity(id: "books", label: "Kinh sách", value: nil),
                    ILTempleAmenityEntity(id: "retreat", label: "Khóa tu", value: nil)
                ],
                visitRules: [
                    "Mùa lễ hội rất đông — đi sớm, giữ tư trang cẩn thận",
                    "Mang giày đế bám khi leo đường đá",
                    "Không thả rác xuống suối Yến"
                ],
                hasUpcomingSchedule: false,
                sessions: [],
                updatedLabel: "09/2026"
            ),
            ILTempleEntity(
                id: "tp-baidinh",
                name: "home.temple.baidinh.name".localized,
                aliases: ["Chùa Bái Đính cổ"],
                latitude: 20.2744, longitude: 105.8647,
                street: "Núi Bái Đính", ward: "Xã Gia Sinh", district: "Huyện Gia Viễn",
                province: "Tỉnh Ninh Bình", region: "Miền Bắc", subRegion: "Đồng bằng sông Hồng",
                sect: "Bắc tông",
                orgInfo: [
                    ILTempleOrgInfoEntity(id: "abbot", label: "Trụ trì", value: nil),
                    ILTempleOrgInfoEntity(id: "founder", label: "Tổ khai sơn", value: "Thiền sư Nguyễn Minh Không (chùa cổ)"),
                    ILTempleOrgInfoEntity(id: "sangha", label: "Giáo hội", value: "GHPGVN tỉnh Ninh Bình")
                ],
                era: "Năm 1136 (chùa cổ) · 2003 (khu chùa mới)", rank: "Thuộc quần thể Tràng An (UNESCO)",
                archStyle: "Quần thể theo trục thần đạo, lối Nội công ngoại quốc", materials: "Gỗ, đá xanh, đồng",
                highlights: [
                    "Tượng Phật Thích Ca bằng đồng dát vàng trong điện Pháp Chủ",
                    "Hành lang La Hán với 500 pho tượng đá"
                ],
                bio: "Chùa Bái Đính cổ gắn với thiền sư Nguyễn Minh Không, vị quốc sư thời Lý, người tìm đến núi Bái Đính tu hành và hái thuốc chữa bệnh cho dân. Chùa cổ nằm trong các hang động tự nhiên trên sườn núi. Từ năm 2003, khu chùa mới được xây dựng ở chân núi với quy mô rất lớn: điện Pháp Chủ, điện Tam Thế, bảo tháp và hành lang La Hán dài hàng kilômét. Nơi đây nằm trong vùng đệm Quần thể danh thắng Tràng An, di sản hỗn hợp văn hóa và thiên nhiên thế giới.",
                regularHours: ILTempleOpeningHoursEntity(openMinute: 360, closeMinute: 1080),
                holidayHours: ILTempleOpeningHoursEntity(openMinute: 300, closeMinute: 1140),
                contacts: [
                    ILTempleContactEntity(id: "phone", label: "Hotline", rawValue: nil),
                    ILTempleContactEntity(id: "fanpage", label: "Fanpage", rawValue: nil),
                    ILTempleContactEntity(id: "website", label: "Website", rawValue: nil),
                    ILTempleContactEntity(id: "email", label: "Email", rawValue: nil)
                ],
                amenities: [
                    ILTempleAmenityEntity(id: "car", label: "Bãi đỗ ô tô", value: "Có · bãi lớn, thu phí"),
                    ILTempleAmenityEntity(id: "bike", label: "Giữ xe máy", value: "Có · thu phí"),
                    ILTempleAmenityEntity(id: "veg", label: "Cơm chay", value: "Có · nhà hàng chay trong khuôn viên"),
                    ILTempleAmenityEntity(id: "books", label: "Kinh sách", value: "Có · quầy văn hóa phẩm"),
                    ILTempleAmenityEntity(id: "retreat", label: "Khóa tu", value: nil)
                ],
                visitRules: [
                    "Khuôn viên rộng — có xe điện đưa đón từ cổng",
                    "Trang phục kín đáo khi vào điện thờ",
                    "Không chạm tay vào tượng La Hán"
                ],
                hasUpcomingSchedule: false,
                sessions: [],
                updatedLabel: "09/2026"
            ),
            ILTempleEntity(
                id: "tp-thienmu",
                name: "home.temple.thienmu.name".localized,
                aliases: ["Linh Mụ tự"],
                latitude: 16.4533, longitude: 107.5447,
                street: "Đường Nguyễn Phúc Nguyên", ward: "Phường Kim Long", district: "TP. Huế",
                province: "TP. Huế", region: "Miền Trung", subRegion: "Bắc Trung Bộ",
                sect: "Bắc tông",
                orgInfo: [
                    ILTempleOrgInfoEntity(id: "abbot", label: "Trụ trì", value: nil),
                    ILTempleOrgInfoEntity(id: "founder", label: "Tổ khai sơn", value: "Chúa Tiên Nguyễn Hoàng"),
                    ILTempleOrgInfoEntity(id: "sangha", label: "Giáo hội", value: "GHPGVN TP. Huế")
                ],
                era: "Năm 1601", rank: "Di tích Quốc gia",
                archStyle: "Kiến trúc cung đình Huế bên đồi Hà Khê", materials: "Gạch, gỗ, đá thanh",
                highlights: [
                    "Tháp Phước Duyên bát giác 7 tầng, cao khoảng 21m",
                    "Đại Hồng Chung đúc năm 1710"
                ],
                bio: "Tương truyền khi chúa Nguyễn Hoàng đi xem địa thế, người dân kể về một bà lão áo đỏ quần lục xuất hiện trên đồi Hà Khê, báo rằng sẽ có chân chúa đến dựng chùa để tụ linh khí. Năm 1601, chúa cho dựng chùa và đặt tên Thiên Mụ. Dưới thời các chúa Nguyễn và triều Nguyễn, chùa nhiều lần được mở rộng; năm 1844 vua Thiệu Trị cho xây tháp Phước Duyên. Nằm bên bờ sông Hương, chùa là biểu tượng của cố đô Huế và vẫn là nơi tu học của chư tăng.",
                regularHours: ILTempleOpeningHoursEntity(openMinute: 480, closeMinute: 1080),
                holidayHours: ILTempleOpeningHoursEntity(openMinute: 360, closeMinute: 1140),
                contacts: [
                    ILTempleContactEntity(id: "phone", label: "Hotline", rawValue: nil),
                    ILTempleContactEntity(id: "fanpage", label: "Fanpage", rawValue: nil),
                    ILTempleContactEntity(id: "website", label: "Website", rawValue: nil),
                    ILTempleContactEntity(id: "email", label: "Email", rawValue: nil)
                ],
                amenities: [
                    ILTempleAmenityEntity(id: "car", label: "Bãi đỗ ô tô", value: "Có · bãi dưới chân đồi"),
                    ILTempleAmenityEntity(id: "bike", label: "Giữ xe máy", value: "Có · thu phí"),
                    ILTempleAmenityEntity(id: "veg", label: "Cơm chay", value: nil),
                    ILTempleAmenityEntity(id: "books", label: "Kinh sách", value: nil),
                    ILTempleAmenityEntity(id: "retreat", label: "Khóa tu", value: nil)
                ],
                visitRules: [
                    "Đây là chốn tu học — giữ yên tĩnh trong khu vực tăng xá",
                    "Không mặc trang phục hở vai, hở gối",
                    "Chỉ chụp ảnh bên ngoài các điện thờ"
                ],
                hasUpcomingSchedule: false,
                sessions: [],
                updatedLabel: "09/2026"
            ),
            ILTempleEntity(
                id: "tp-linhung",
                name: "home.temple.linhung.name".localized,
                aliases: ["Chùa Linh Ứng Bãi Bụt", "Chùa Quan Âm Sơn Trà"],
                latitude: 16.1003, longitude: 108.2778,
                street: "Đường Hoàng Sa", ward: "Phường Thọ Quang", district: "Quận Sơn Trà",
                province: "TP. Đà Nẵng", region: "Miền Trung", subRegion: "Nam Trung Bộ",
                sect: "Bắc tông",
                orgInfo: [
                    ILTempleOrgInfoEntity(id: "abbot", label: "Trụ trì", value: nil),
                    ILTempleOrgInfoEntity(id: "founder", label: "Tổ khai sơn", value: nil),
                    ILTempleOrgInfoEntity(id: "sangha", label: "Giáo hội", value: "GHPGVN TP. Đà Nẵng")
                ],
                era: "Năm 2004 – 2010", rank: "Không xếp hạng",
                archStyle: "Kiến trúc Phật giáo hiện đại hướng biển", materials: "Bê tông, đá cẩm thạch",
                highlights: [
                    "Tượng Quán Thế Âm cao 67m nhìn ra vịnh Đà Nẵng",
                    "18 tượng La Hán bằng đá cẩm thạch dọc sân chùa"
                ],
                bio: "Chùa Linh Ứng Bãi Bụt tọa lạc trên bán đảo Sơn Trà, lưng tựa núi, mặt hướng ra biển. Theo lời kể của ngư dân, vùng biển này từng dạt vào một pho tượng Phật, nên người dân gọi là Bãi Bụt. Chùa được khởi công năm 2004 và hoàn thành năm 2010, nổi bật với tượng Quán Thế Âm trắng cao 67m, mặt nhìn ra biển như che chở cho ngư dân ra khơi. Từ sân chùa có thể ngắm toàn cảnh thành phố và vịnh Đà Nẵng.",
                regularHours: ILTempleOpeningHoursEntity(openMinute: 360, closeMinute: 1080),
                holidayHours: ILTempleOpeningHoursEntity(openMinute: 300, closeMinute: 1140),
                contacts: [
                    ILTempleContactEntity(id: "phone", label: "Hotline", rawValue: nil),
                    ILTempleContactEntity(id: "fanpage", label: "Fanpage", rawValue: nil),
                    ILTempleContactEntity(id: "website", label: "Website", rawValue: nil),
                    ILTempleContactEntity(id: "email", label: "Email", rawValue: nil)
                ],
                amenities: [
                    ILTempleAmenityEntity(id: "car", label: "Bãi đỗ ô tô", value: "Có · miễn phí"),
                    ILTempleAmenityEntity(id: "bike", label: "Giữ xe máy", value: "Có · miễn phí"),
                    ILTempleAmenityEntity(id: "veg", label: "Cơm chay", value: "Tùy hỷ · ngày lễ lớn"),
                    ILTempleAmenityEntity(id: "books", label: "Kinh sách", value: "Có · quầy kinh sách"),
                    ILTempleAmenityEntity(id: "retreat", label: "Khóa tu", value: nil)
                ],
                visitRules: [
                    "Đường lên bán đảo nhiều dốc — đi chậm, cẩn thận",
                    "Không cho khỉ ăn trong khu vực chùa",
                    "Trang phục kín đáo"
                ],
                hasUpcomingSchedule: false,
                sessions: [],
                updatedLabel: "09/2026"
            ),
            ILTempleEntity(
                id: "tp-truclam",
                name: "home.temple.truclam.name".localized,
                aliases: ["Thiền viện Trúc Lâm Đà Lạt", "Chùa Trúc Lâm Phượng Hoàng"],
                latitude: 11.9014, longitude: 108.4344,
                street: "Hồ Tuyền Lâm", ward: "Phường 3", district: "TP. Đà Lạt",
                province: "Tỉnh Lâm Đồng", region: "Tây Nguyên", subRegion: "Tây Nguyên",
                sect: "Thiền phái Trúc Lâm",
                orgInfo: [
                    ILTempleOrgInfoEntity(id: "abbot", label: "Trụ trì", value: nil),
                    ILTempleOrgInfoEntity(id: "founder", label: "Tổ khai sơn", value: "Hòa thượng Thích Thanh Từ"),
                    ILTempleOrgInfoEntity(id: "sangha", label: "Giáo hội", value: "GHPGVN tỉnh Lâm Đồng")
                ],
                era: "Năm 1993", rank: "Không xếp hạng",
                archStyle: "Thiền viện theo lối Lý – Trần trên núi Phượng Hoàng", materials: "Gỗ, ngói, đá",
                highlights: [
                    "Nhìn xuống hồ Tuyền Lâm",
                    "Khu nội viện dành riêng cho chư tăng tu thiền"
                ],
                bio: "Thiền viện Trúc Lâm Đà Lạt do Hòa thượng Thích Thanh Từ khởi dựng năm 1993 trên núi Phượng Hoàng, bên hồ Tuyền Lâm, nhằm phục hưng dòng thiền Trúc Lâm Yên Tử do vua Trần Nhân Tông sáng lập. Khuôn viên chia thành ngoại viện đón khách thập phương và nội viện dành cho tăng ni tu tập. Cảnh sắc thông, hoa và mặt hồ phẳng lặng tạo nên không gian rất hợp với tinh thần thiền định. Thiền viện là một trong những điểm tham quan Phật giáo nổi tiếng nhất của Đà Lạt.",
                regularHours: ILTempleOpeningHoursEntity(openMinute: 420, closeMinute: 1020),
                holidayHours: ILTempleOpeningHoursEntity(openMinute: 420, closeMinute: 1020),
                contacts: [
                    ILTempleContactEntity(id: "phone", label: "Hotline", rawValue: nil),
                    ILTempleContactEntity(id: "fanpage", label: "Fanpage", rawValue: nil),
                    ILTempleContactEntity(id: "website", label: "Website", rawValue: nil),
                    ILTempleContactEntity(id: "email", label: "Email", rawValue: nil)
                ],
                amenities: [
                    ILTempleAmenityEntity(id: "car", label: "Bãi đỗ ô tô", value: "Có · bãi dưới chân thiền viện"),
                    ILTempleAmenityEntity(id: "bike", label: "Giữ xe máy", value: "Có · thu phí"),
                    ILTempleAmenityEntity(id: "veg", label: "Cơm chay", value: nil),
                    ILTempleAmenityEntity(id: "books", label: "Kinh sách", value: "Có · sách thiền của HT Thích Thanh Từ"),
                    ILTempleAmenityEntity(id: "retreat", label: "Khóa tu", value: "Khóa tu thiền cho Phật tử theo đợt")
                ],
                visitRules: [
                    "Không vào khu nội viện",
                    "Nói nhỏ, đi nhẹ trong chánh điện",
                    "Trang phục kín đáo, mang áo ấm"
                ],
                hasUpcomingSchedule: false,
                sessions: [],
                updatedLabel: "09/2026"
            ),
            ILTempleEntity(
                id: "tp-vinhnghiem",
                name: "home.temple.vinhnghiem.name".localized,
                aliases: [],
                latitude: 10.7905, longitude: 106.6835,
                street: "339 Nam Kỳ Khởi Nghĩa", ward: "Phường 7", district: "Quận 3",
                province: "TP. Hồ Chí Minh", region: "Miền Nam", subRegion: "Đông Nam Bộ",
                sect: "Bắc tông",
                orgInfo: [
                    ILTempleOrgInfoEntity(id: "abbot", label: "Trụ trì", value: nil),
                    ILTempleOrgInfoEntity(id: "founder", label: "Tổ khai sơn", value: "HT Thích Tâm Giác · HT Thích Thanh Kiểm"),
                    ILTempleOrgInfoEntity(id: "sangha", label: "Giáo hội", value: "GHPGVN TP. Hồ Chí Minh")
                ],
                era: "Năm 1964 – 1971", rank: nil,
                archStyle: "Kiến trúc chùa Bắc Bộ phối hợp vật liệu hiện đại", materials: "Bê tông cốt thép, gỗ, ngói",
                highlights: [
                    "Tháp Quan Âm 7 tầng cao gần 40m",
                    "Đại hồng chung nặng khoảng 2 tấn"
                ],
                bio: "Chùa Vĩnh Nghiêm được xây dựng từ năm 1964 đến 1971 do Hòa thượng Thích Tâm Giác và Hòa thượng Thích Thanh Kiểm chủ trì, với mong ước lưu giữ truyền thống của Tổ đình Vĩnh Nghiêm ở Bắc Giang giữa lòng Sài Gòn. Chùa mang dáng dấp kiến trúc Bắc Bộ nhưng dùng vật liệu hiện đại, nổi bật với tháp Quan Âm bảy tầng và cổng tam quan rộng. Đây là một trong những ngôi chùa lớn và sầm uất nhất thành phố, đặc biệt đông vui vào dịp Tết và mùa Vu Lan.",
                regularHours: ILTempleOpeningHoursEntity(openMinute: 420, closeMinute: 1110),
                holidayHours: ILTempleOpeningHoursEntity(openMinute: 300, closeMinute: 1260),
                contacts: [
                    ILTempleContactEntity(id: "phone", label: "Hotline", rawValue: nil),
                    ILTempleContactEntity(id: "fanpage", label: "Fanpage", rawValue: nil),
                    ILTempleContactEntity(id: "website", label: "Website", rawValue: nil),
                    ILTempleContactEntity(id: "email", label: "Email", rawValue: nil)
                ],
                amenities: [
                    ILTempleAmenityEntity(id: "car", label: "Bãi đỗ ô tô", value: "Có · sân chùa, hạn chế"),
                    ILTempleAmenityEntity(id: "bike", label: "Giữ xe máy", value: "Có · thu phí"),
                    ILTempleAmenityEntity(id: "veg", label: "Cơm chay", value: "Tùy hỷ · ngày lễ lớn"),
                    ILTempleAmenityEntity(id: "books", label: "Kinh sách", value: "Có · nhà sách trong chùa"),
                    ILTempleAmenityEntity(id: "retreat", label: "Khóa tu", value: "Khóa tu mùa hè cho thanh thiếu niên")
                ],
                visitRules: [
                    "Trang phục lịch sự khi vào chánh điện",
                    "Hạn chế quay phim trong giờ hành lễ",
                    "Giữ gìn vệ sinh chung"
                ],
                hasUpcomingSchedule: false,
                sessions: [],
                updatedLabel: "09/2026"
            )
        ]
    }

    /// Catalog tĩnh 2 thời khóa sắp tới khớp `isTemple` trong design handoff — hiện chỉ Từ Quang
    /// có `hasUpcomingSchedule: true` nên dùng chung template này.
    private static func makeSessionCatalog() -> [ILTempleSessionEntity] {
        [
            ILTempleSessionEntity(
                id: "temple.session.vulan",
                title: "Tụng Kinh Vu Lan",
                subtitle: "CN 13/9 · 8:00 · Chánh điện",
                trailingText: "Đã ghi danh",
                tone: .gold,
                glyph: .book
            ),
            ILTempleSessionEntity(
                id: "temple.session.meditation",
                title: "Khóa thiền tối",
                subtitle: "T5 17/9 · 19:00 · Thầy Minh Đạo",
                trailingText: "Ghi danh",
                tone: .green,
                glyph: .circle
            )
        ]
    }
}
