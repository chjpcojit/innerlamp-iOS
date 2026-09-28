//
//  ILDeityUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILDeityUseCase {
    /// Trả về dữ liệu đầy đủ của 1 vị Phật / Bồ Tát theo `deityID`. Nếu không tìm thấy, rơi về
    /// vị đầu tiên trong catalog (giữ màn luôn hiển thị được nội dung).
    func getInitialState(deityID: String) -> ILDeityEntity

    /// Toàn bộ catalog "Phật & Bồ Tát" — dùng để dựng bản tóm tắt cho carousel ở Trang chủ
    /// (`ILHomeUseCase` map sang `ILHomeDeityEntity`).
    func getAllDeities() -> [ILDeityEntity]

    /// Ngày vía gần nhất (tính từ hôm nay, theo âm lịch Việt Nam) trong các ngày vía của vị này;
    /// `nil` nếu vị không có ngày vía nào.
    func upcomingMemorialDay(for deity: ILDeityEntity) -> ILDeityUpcomingMemorialDayEntity?

    /// Các bộ kinh liên quan (tách từ `canonicalSource`), kèm `sutraID` khi đã có trong Thư viện.
    func relatedSutras(for deity: ILDeityEntity) -> [ILDeityRelatedSutraEntity]
}

final class ILDeityUseCaseImpl: ILDeityUseCase {

    // TODO: khi có API / nguồn dữ liệu catalog thật, thay catalog mock dưới đây bằng dữ liệu từ
    // `Docs/Assert/Data/phat_botat.json` (networkService hoặc JSON bundled). Nội dung này là DATA
    // (danh xưng, tiểu sử, mật chú...), không phải UI copy nên để nguyên chuỗi tiếng Việt thay vì
    // đưa qua `.localized` — khác với nhãn UI (được `ILDeityViewModel` resolve từ key).
    /// Nguồn "hôm nay" — tiêm vào để test tính ngày vía không phụ thuộc đồng hồ máy.
    private let now: () -> Date
    private let calendar: Calendar

    init(now: @escaping () -> Date = Date.init) {
        self.now = now
        var calendar = Calendar(identifier: .gregorian)
        // Âm lịch Việt Nam tính theo UTC+7 — đếm ngày cũng theo múi giờ đó cho nhất quán.
        calendar.timeZone = TimeZone(secondsFromGMT: 7 * 3600) ?? .current
        self.calendar = calendar
    }

    func getInitialState(deityID: String) -> ILDeityEntity {
        let catalog = Self.makeCatalog()
        return catalog.first { $0.id == deityID } ?? catalog[0]
    }

    func getAllDeities() -> [ILDeityEntity] {
        Self.makeCatalog()
    }

    func upcomingMemorialDay(for deity: ILDeityEntity) -> ILDeityUpcomingMemorialDayEntity? {
        deity.memorialDays
            .compactMap { nextOccurrence(of: $0) }
            .min { $0.daysUntil < $1.daysUntil }
    }

    func relatedSutras(for deity: ILDeityEntity) -> [ILDeityRelatedSutraEntity] {
        deity.canonicalSources.map { title in
            ILDeityRelatedSutraEntity(title: title, sutraID: Self.librarySutraIDs[title])
        }
    }

    // MARK: - Memorial day

    /// Quét tối đa ~13 tháng tới để tìm ngày dương ứng với ngày/tháng âm của lần vía kế tiếp (bỏ
    /// qua tháng nhuận). Ngày 30 âm rơi vào tháng thiếu (29 ngày) được tính là ngày 29 — khớp
    /// ghi chú "Tháng thiếu tính ngày 29" của catalog.
    private func nextOccurrence(of memorialDay: ILDeityMemorialDayEntity) -> ILDeityUpcomingMemorialDayEntity? {
        let today = calendar.startOfDay(for: now())
        guard let base = calendar.date(byAdding: .hour, value: 12, to: today) else { return nil }

        for offset in 0..<Self.memorialDaySearchWindow {
            guard let date = calendar.date(byAdding: .day, value: offset, to: base) else { continue }
            let lunar = ILLunarCalendar.solarToLunar(date: date, calendar: calendar)
            guard !lunar.isLeapMonth, lunar.month == memorialDay.lunarMonth else { continue }

            if lunar.day == memorialDay.lunarDay || isLastDayStandingInForDay30(lunar, memorialDay, date) {
                return ILDeityUpcomingMemorialDayEntity(memorialDay: memorialDay, date: date, daysUntil: offset)
            }
        }
        return nil
    }

    private func isLastDayStandingInForDay30(
        _ lunar: ILLunarCalendar.LunarDate,
        _ memorialDay: ILDeityMemorialDayEntity,
        _ date: Date
    ) -> Bool {
        guard memorialDay.lunarDay == 30, lunar.day == 29,
              let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { return false }
        return ILLunarCalendar.solarToLunar(date: nextDate, calendar: calendar).day == 1
    }

    private static let memorialDaySearchWindow = 400

    /// Bộ kinh trong `canonicalSource` đã có trong catalog Thư viện (`ILLibraryUseCaseImpl`) —
    /// chỉ những mục này có nút "Mở". TODO: bỏ bảng tra khi catalog kinh thật có API tra theo tên.
    private static let librarySutraIDs: [String: String] = [
        "Kinh A Di Đà": "sutra.amida"
    ]

    // MARK: - Catalog

    /// Catalog tĩnh 18 vị (6 Phật + 12 Bồ Tát) khớp `Docs/Assert/Data/phat_botat.json`.
    private static func makeCatalog() -> [ILDeityEntity] {
        [
            // MARK: - Chư Phật
            ILDeityEntity(
                id: "buddha_shakyamuni",
                kind: .buddha,
                nameVi: "Thích Ca Mâu Ni Phật",
                nameSanskrit: "Śākyamuni Buddha",
                nameChinese: "釋迦牟尼佛",
                titleHonorific: "Bổn Sư Thích Ca Mâu Ni Phật",
                canonicalSource: "Trường Bộ Kinh (Dīgha Nikāya), Kinh Phổ Diệu (Lalitavistara Sūtra)",
                coreVirtue: "Toàn Giác (Bậc Thầy giác ngộ chỉ đường giải thoát khỏi luân hồi cõi Ta Bà)",
                pureLand: "Cõi Ta Bà (Saha World)",
                memorialDays: [
                    ILDeityMemorialDayEntity(lunarDay: 8, lunarMonth: 2, eventName: "Ngày Xuất gia"),
                    ILDeityMemorialDayEntity(lunarDay: 15, lunarMonth: 2, eventName: "Ngày Nhập Niết-bàn"),
                    ILDeityMemorialDayEntity(lunarDay: 15, lunarMonth: 4, eventName: "Ngày Đại lễ Phật Đản (Tam Hợp)"),
                    ILDeityMemorialDayEntity(lunarDay: 8, lunarMonth: 12, eventName: "Ngày Thành đạo")
                ],
                iconography: ILDeityIconographyEntity(
                    posture: "Ngồi kiết già trên tòa sen, nhục kế nổi cao, ngực có thể có tướng chữ Vạn",
                    mountOrThrone: "Tòa Kim Cương ngự hoa sen",
                    sacredArtifacts: ["Bát khất thực", "Tay phải thủ ấn Xúc Địa (Bhūmisparśa Mudrā) hoặc Chuyển Pháp Luân"],
                    symbolicMeaning: "Ấn Xúc Địa biểu trưng cho việc lấy đại địa làm chứng cho sự giác ngộ tối thượng không lay chuyển."
                ),
                biographySummary: "Thái tử Tất Đạt Đa (Siddhārtha Gautama) sinh ra tại vương quốc Thích Ca (Ấn Độ cổ đại). Chứng kiến sinh lão bệnh tử, Ngài từ bỏ hoàng cung xuất gia tầm đạo, chứng ngộ Vô Thượng Chánh Đẳng Chánh Giác dưới cội Bồ Đề và dành 45 năm thuyết pháp độ sinh.",
                greatVows: [
                    "Thị hiện vào đời ác năm trược (Ngũ trược ác thế) để cứu độ chúng sinh đau khổ.",
                    "Khai thị chúng sinh ngộ nhập Phật tri kiến, dứt sạch luân hồi."
                ],
                mantra: ILDeityMantraEntity(
                    shortSanskrit: "Oṃ Muni Muni Mahāmuni Śākyamuni Svāhā",
                    shortSinoVietnamese: "Án Mâu Ni Mâu Ni Ma Ha Mâu Ni Thích Ca Mâu Ni Thoa Ha",
                    dharaniName: "Thích Ca Mâu Ni Phật Căn Bản Chân Ngôn",
                    dharaniSnippet: "Nam mô tát bà đà tha, a nga đà gia, đát điệt tha: Án mâu ni mâu ni ma ha mâu ni thích ca mâu ni dạ ta bà ha."
                )
            ),
            ILDeityEntity(
                id: "buddha_amitabha",
                kind: .buddha,
                nameVi: "A Di Đà Phật",
                nameSanskrit: "Amitābha Buddha / Amitāyus",
                nameChinese: "阿彌陀佛",
                titleHonorific: "Nam Mô Tiếp Dẫn Đạo Sư A Di Đà Phật",
                canonicalSource: "Kinh Vô Lượng Thọ, Kinh A Di Đà, Kinh Quán Vô Lượng Thọ",
                coreVirtue: "Từ Bi Tiếp Dẫn (Ánh sáng vô lượng, Thọ mạng vô lượng)",
                pureLand: "Tây Phương Cực Lạc (Sukhāvatī)",
                memorialDays: [
                    ILDeityMemorialDayEntity(lunarDay: 17, lunarMonth: 11, eventName: "Ngày Vía Đức Phật A Di Đà")
                ],
                iconography: ILDeityIconographyEntity(
                    posture: "Đứng tiếp dẫn hoặc ngồi kiết già, mắt nhìn xuống cõi thế gian",
                    mountOrThrone: "Đài sen báu nâng đỡ",
                    sacredArtifacts: ["Đài sen báu trên tay trái", "Tay phải duỗi xuống kết ấn Tiếp Dẫn"],
                    symbolicMeaning: "Tượng trưng cho sự đón rước chúng sinh vãng sanh về cõi Cực Lạc giải thoát."
                ),
                biographySummary: "Tiền thân là Tỳ-kheo Pháp Tạng (Dharmākara), đối trước Đức Thế Tự Tại Vương Như Lai phát khởi 48 lời đại nguyện kiến tạo quốc độ Tây Phương Cực Lạc thanh tịnh trang nghiêm để cứu vớt muôn loài.",
                greatVows: [
                    "Bốn mươi tám đại nguyện cứu độ mười phương chúng sinh niệm danh hiệu mười niệm liền được vãng sanh.",
                    "Tiếp dẫn hương linh người tu Tịnh nghiệp khi lâm chung về cõi thanh tịnh không còn thối chuyển."
                ],
                mantra: ILDeityMantraEntity(
                    shortSanskrit: "Oṃ Amṛta Teje Hara Hūṃ",
                    shortSinoVietnamese: "Án A Mật Rị Đa Tế Già Đê Hạ Lăng Hồng",
                    dharaniName: "Bạt Nhất Thiết Nghiệp Chướng Căn Bản Đắc Sinh Tịnh Độ Đà La Ni (Chú Vãng Sanh)",
                    dharaniSnippet: "Nam mô a di đa bà dạ, đa tha già đa dạ, đa địa dạ tha: A di rị đô bà tỳ, a di rị đa tất đam bà tỳ..."
                )
            ),
            ILDeityEntity(
                id: "buddha_bhaisajyaguru",
                kind: .buddha,
                nameVi: "Dược Sư Lưu Ly Quang Vương Phật",
                nameSanskrit: "Bhaiṣajyaguru Buddha",
                nameChinese: "藥師琉璃光王佛",
                titleHonorific: "Nam Mô Dược Sư Lưu Ly Quang Vương Phật",
                canonicalSource: "Kinh Dược Sư Bổn Nguyện Công Đức",
                coreVirtue: "Trị Liệu & Tiêu Trừ Tai Họa (Chữa lành thân tâm bệnh và diệt trừ đói khổ)",
                pureLand: "Đông Phương Tịnh Lưu Ly",
                memorialDays: [
                    ILDeityMemorialDayEntity(lunarDay: 30, lunarMonth: 9, eventName: "Ngày Vía Đức Phật Dược Sư (Tháng thiếu tính ngày 29)")
                ],
                iconography: ILDeityIconographyEntity(
                    posture: "Ngồi kiết già trên đài sen, toàn thân tỏa ánh sắc xanh lưu ly trong suốt",
                    mountOrThrone: "Tòa sen lưu ly",
                    sacredArtifacts: ["Hũ thuốc cam lồ (hoặc bình bát ngọc)", "Cành thuốc Myrobalan (Kha tử) trên tay"],
                    symbolicMeaning: "Xua tan bóng tối vô minh và tẩy trừ tất cả độc tố thân bệnh, tâm bệnh của chúng sinh."
                ),
                biographySummary: "Khi còn tu Bồ Tát đạo, Ngài phát 12 đại nguyện cứu giúp chúng sinh cõi thế tục thoát khỏi các bệnh tật nan y, thân thể tật nguyền, nghèo hèn đói rách, hướng tâm về con đường chánh pháp an vui.",
                greatVows: [
                    "Nguyện thân sáng như ngọc lưu ly, chiếu rọi muôn cõi phá tan tăm tối mê lầm.",
                    "Nguyện cho mọi chúng sinh bị bệnh khổ, không thầy không thuốc, khi nghe danh hiệu Ngài đều tiêu trừ bệnh tật, thân tâm an lạc."
                ],
                mantra: ILDeityMantraEntity(
                    shortSanskrit: "Oṃ Bhaiṣajye Bhaiṣajye Bhaiṣajya Samudgate Svāhā",
                    shortSinoVietnamese: "Án Bệ Sát Thệ Bệ Sát Thệ Bệ Sát Xã Tam Một Yết Đế Thoa Ha",
                    dharaniName: "Dược Sư Quán Đảnh Chân Ngôn",
                    dharaniSnippet: "Nam mô Bạc già phạt đế, Bệ sát xã lũ lô thích lưu ly, Bát lạt bà hắc ra xà dã..."
                )
            ),
            ILDeityEntity(
                id: "buddha_maitreya",
                kind: .buddha,
                nameVi: "Di Lặc Tôn Phật",
                nameSanskrit: "Maitreya Buddha",
                nameChinese: "彌勒佛",
                titleHonorific: "Đương Lai Hạ Sanh Di Lặc Tôn Phật",
                canonicalSource: "Kinh Di Lặc Hạ Sanh, Kinh Di Lặc Thượng Sanh",
                coreVirtue: "Hỷ Xả & Vui Tươi (Tâm từ vô lượng, mang lại hỷ lạc)",
                pureLand: "Cung Trời Đâu Suất (Tuṣita Heaven) / Tương lai hạ sanh cõi Ta Bà",
                memorialDays: [
                    ILDeityMemorialDayEntity(lunarDay: 1, lunarMonth: 1, eventName: "Ngày Vía Đức Phật Di Lặc (Mùng 1 Tết Nguyên Đán)")
                ],
                iconography: ILDeityIconographyEntity(
                    posture: "Hình tướng hóa thân Bố Đại Hòa Thượng mập mạp, bụng to, nụ cười hoan hỷ rạng rỡ",
                    mountOrThrone: "Ngồi thoải mái tự tại trên túi vải hoặc tựa gốc cây",
                    sacredArtifacts: ["Túi vải càn khôn gom phiền não", "Xâu chuỗi hạt hoặc thỏi vàng biểu trưng phúc lộc"],
                    symbolicMeaning: "Bụng to dung chứa chuyện khó dung của nhân gian, miệng cười mở rộng niềm vui hỷ xả."
                ),
                biographySummary: "Hiện là một vị Nhất Sinh Bổ Xứ Bồ Tát đang thuyết pháp tại nội viện cung trời Đâu Suất. Trong tương lai khi giáo pháp Thích Ca suy tàn, Ngài sẽ hạ sanh nhân gian, thành đạo dưới cội cây Long Hoa độ thoát vô lượng chúng sinh.",
                greatVows: [
                    "Tu hạnh Từ tâm tam muội, không ăn thịt chúng sinh, đem lại an lạc tuyệt đối.",
                    "Mở Hội Long Hoa tiếp nhận và hóa độ toàn bộ người đã kết duyên với Phật pháp."
                ],
                mantra: ILDeityMantraEntity(
                    shortSanskrit: "Oṃ Maitreya Maitreya Mahāmaitreya Svāhā",
                    shortSinoVietnamese: "Án Mai Trê Da Mai Trê Da Ma Ha Mai Trê Da Thoa Ha",
                    dharaniName: "Di Lặc Bồ Tát Căn Bản Chân Ngôn",
                    dharaniSnippet: "Nam mô tam mãn đa một đà nẫm, mai đát lệ dã tát bà ha."
                )
            ),
            ILDeityEntity(
                id: "buddha_vairocana",
                kind: .buddha,
                nameVi: "Tỳ Lô Giá Na Phật",
                nameSanskrit: "Vairocana Buddha",
                nameChinese: "毗盧遮那佛 / 大日如來",
                titleHonorific: "Đại Nhật Như Lai (Pháp Thân Phật)",
                canonicalSource: "Kinh Hoa Nghiêm (Avataṃsaka Sūtra), Kinh Đại Nhật (Mahāvairocana Tantra)",
                coreVirtue: "Pháp Thân Biến Chiếu (Ánh sáng trí tuệ chiếu soi khắp pháp giới bình đẳng)",
                pureLand: "Liên Hoa Tạng Thế Giới (Padmagarbha)",
                memorialDays: [
                    ILDeityMemorialDayEntity(lunarDay: 15, lunarMonth: 4, eventName: "Tôn vinh cùng mùa Phật Đản")
                ],
                iconography: ILDeityIconographyEntity(
                    posture: "Ngồi kiết già, hai tay kết ấn Trí Quyền (Bodhiraṅgī Mudrā) hoặc ấn Thiền Định",
                    mountOrThrone: "Tòa ngàn cánh sen báu",
                    sacredArtifacts: ["Bánh xe Pháp Luân tám nan hoa", "Vương miện Ngũ Phật"],
                    symbolicMeaning: "Thể hiện chân lý vũ trụ tuyệt đối, thực tại tối hậu của vạn pháp không sinh không diệt."
                ),
                biographySummary: "Là biểu hiện tối cao của Pháp Thân (Dharmakāya) trong Tam Thân Phật. Toàn bộ vũ trụ và cõi tịnh độ đều hiển lộ từ tự tính thanh tịnh của Ngài.",
                greatVows: [
                    "Chiếu soi ánh sáng đại trí tuệ phá tan bóng tối si ám căn bản của vô minh.",
                    "Duy trì trật tự chân lý của muôn cõi pháp giới bình đẳng."
                ],
                mantra: ILDeityMantraEntity(
                    shortSanskrit: "Oṃ Vairocana Hūṃ",
                    shortSinoVietnamese: "Án Tỳ Lô Giá Na Hồng",
                    dharaniName: "Quang Minh Chân Ngôn",
                    dharaniSnippet: "Án a mô già vĩ lô giá nẵng ma cáp mẫu đức lạt ma nỉ bát đức mạ cập phạp lạt bát lạt phạp nhĩ đả dã hồng."
                )
            ),
            ILDeityEntity(
                id: "buddha_dipankara",
                kind: .buddha,
                nameVi: "Nhiên Đăng Cổ Phật",
                nameSanskrit: "Dīpaṅkara Buddha",
                nameChinese: "燃燈古佛",
                titleHonorific: "Định Quang Như Lai",
                canonicalSource: "Kinh Kim Cương Bát Nhã, Đại Trí Độ Lược Luận",
                coreVirtue: "Truyền Đăng & Thụ Ký (Ngọn đèn trí tuệ thắp sáng tương lai)",
                pureLand: "Cõi Quá Khứ trang nghiêm",
                memorialDays: [
                    ILDeityMemorialDayEntity(lunarDay: 22, lunarMonth: 8, eventName: "Ngày Vía Đức Phật Nhiên Đăng")
                ],
                iconography: ILDeityIconographyEntity(
                    posture: "Đứng hoặc ngồi trang nghiêm cổ kính, tỏa ánh lửa sáng ngời",
                    mountOrThrone: "Tòa sen cổ",
                    sacredArtifacts: ["Ngọn đèn trí tuệ", "Ấn Vô Úy"],
                    symbolicMeaning: "Biểu thị sự kế thừa ánh sáng trí tuệ từ vô lượng kiếp trước cho đến đời nay."
                ),
                biographySummary: "Là vị Cổ Phật xuất hiện trong thời quá khứ xa xưa. Trong một tiền kiếp, khi Bồ Tát Thích Ca còn là thiện nam tử Nho Đồng (Māṇava), chàng đã trải tóc trên vũng bùn ướt để Phật Nhiên Đăng bước qua và được Ngài thụ ký sau này sẽ thành Phật.",
                greatVows: [
                    "Thắp sáng ngọn đèn chánh pháp truyền thừa tiếp nối qua các thời kỳ kiếp nạn.",
                    "Thụ ký cho các hành giả Bồ Tát đạo kiên định tiến bước thành tựu Phật quả."
                ],
                mantra: ILDeityMantraEntity(
                    shortSanskrit: "Oṃ Dīpaṅkara Mahādīpa Svāhā",
                    shortSinoVietnamese: "Án Định Quang Ma Ha Định Quang Thoa Ha",
                    dharaniName: "Định Quang Phật Chân Ngôn",
                    dharaniSnippet: "Nam mô định quang như lai gia, đát điệt tha: Án đê bà đê bà ma ha đê bà thích phạp la hồng."
                )
            ),

            // MARK: - Chư Bồ Tát
            ILDeityEntity(
                id: "bodhisattva_avalokiteshvara",
                kind: .bodhisattva,
                nameVi: "Quán Thế Âm Bồ Tát",
                nameSanskrit: "Avalokiteśvara Bodhisattva",
                nameChinese: "觀世音菩薩",
                titleHonorific: "Đại Bi Quán Thế Âm Bồ Tát",
                canonicalSource: "Kinh Diệu Pháp Liên Hoa (Phẩm Phổ Môn), Kinh Lăng Nghiêm",
                coreVirtue: "Đại Bi (Lắng nghe âm thanh cứu khổ tìm đến giải thoát)",
                pureLand: "Phổ Đà Lạc Ca Sơn (Potalaka) / Thị giả cõi Tây Phương Cực Lạc",
                memorialDays: [
                    ILDeityMemorialDayEntity(lunarDay: 19, lunarMonth: 2, eventName: "Ngày Đản sinh Quán Thế Âm"),
                    ILDeityMemorialDayEntity(lunarDay: 19, lunarMonth: 6, eventName: "Ngày Thành đạo Quán Thế Âm"),
                    ILDeityMemorialDayEntity(lunarDay: 19, lunarMonth: 9, eventName: "Ngày Xuất gia Quán Thế Âm")
                ],
                iconography: ILDeityIconographyEntity(
                    posture: "Đứng hoặc ngồi tự tại trên đài sen báu hoặc mây ngũ sắc",
                    mountOrThrone: "Tòa sen hoặc ngự trên đầu rồng (Quán Âm Nam Hải)",
                    sacredArtifacts: ["Bình tịnh thủy chứa nước cam lồ", "Cành dương liễu nhu hòa"],
                    symbolicMeaning: "Nước cam lồ thanh tịnh rưới mát tâm can, cành dương liễu dẻo dai biểu thị tính nhẫn nhục."
                ),
                biographySummary: "Là hiện thân của lòng đại bi vô tận. Ngài quán sát mọi âm thanh đau khổ kêu cầu trong mười phương thế giới, ứng hóa 32 thân hình tướng thích hợp để vào đời cứu độ chúng sinh.",
                greatVows: [
                    "Khi chúng sinh gặp khổ nạn ách tai, nhất tâm xưng tụng danh hiệu liền được cứu vớt.",
                    "Tận diệt đau khổ của tất cả ba đường dữ địa ngục, ngạ quỷ, súc sinh."
                ],
                mantra: ILDeityMantraEntity(
                    shortSanskrit: "Oṃ Maṇi Padme Hūṃ",
                    shortSinoVietnamese: "Án Ma Ni Bát Mê Hồng (Lục Tự Đại Minh Chân Ngôn)",
                    dharaniName: "Thiên Thủ Thiên Nhãn Vô Ngại Đại Bi Tâm Đà La Ni",
                    dharaniSnippet: "Nam mô hắc ra đát na đa ra dạ da. Nam mô a rị da, bà lô kiết đế thước bát ra da..."
                )
            ),
            ILDeityEntity(
                id: "bodhisattva_manjushri",
                kind: .bodhisattva,
                nameVi: "Văn Thù Sư Lợi Bồ Tát",
                nameSanskrit: "Mañjuśrī Bodhisattva",
                nameChinese: "文殊師利菩薩",
                titleHonorific: "Đại Trí Văn Thù Sư Lợi Bồ Tát",
                canonicalSource: "Kinh Hoa Nghiêm, Kinh Duy Ma Cật Sở Thuyết",
                coreVirtue: "Đại Trí (Trí tuệ Bát Nhã thực tướng đoạn diệt vô minh)",
                pureLand: "Thanh Lương Sơn (Núi Ngũ Đài Sơn) / Thị giả tả biên Phật Thích Ca",
                memorialDays: [
                    ILDeityMemorialDayEntity(lunarDay: 4, lunarMonth: 4, eventName: "Ngày Vía Đức Bồ Tát Văn Thù")
                ],
                iconography: ILDeityIconographyEntity(
                    posture: "Ngồi kiết già uy dũng trên lưng sư tử xanh",
                    mountOrThrone: "Sư tử xanh (Thanh sư)",
                    sacredArtifacts: ["Gươm báu trí tuệ giơ cao tay phải", "Cuốn kinh Bát Nhã trên cành sen tay trái"],
                    symbolicMeaning: "Gươm báu chém đứt mọi lưới nghi phiền não, tiếng rống sư tử phá tan sự mê muội si ám."
                ),
                biographySummary: "Là bậc thượng thủ của hàng Bồ Tát trong các hội chúng Phật giáo Đại Thừa, biểu trưng cho trí tuệ căn bản không phân biệt. Ngài thường chất vấn các đại đệ tử và triển khai giáo lý thậm thâm Bát Nhã.",
                greatVows: [
                    "Nguyện dẫn dắt toàn bộ chúng sinh bước lên thuyền Bát Nhã trí tuệ giải thoát.",
                    "Trở thành thầy chỉ đường của chư Phật trong ba đời quá khứ, hiện tại, vị lai."
                ],
                mantra: ILDeityMantraEntity(
                    shortSanskrit: "Oṃ A Ra Pa Ca Na Dhīḥ",
                    shortSinoVietnamese: "Án A Ra Ba Giá Na Đê",
                    dharaniName: "Văn Thù Sư Lợi Bồ Tát Ngũ Tự Chân Ngôn",
                    dharaniSnippet: "Án a ra ba giá na đê đê đê..."
                )
            ),
            ILDeityEntity(
                id: "bodhisattva_samantabhadra",
                kind: .bodhisattva,
                nameVi: "Phổ Hiền Bồ Tát",
                nameSanskrit: "Samantabhadra Bodhisattva",
                nameChinese: "普賢菩薩",
                titleHonorific: "Đại Hạnh Phổ Hiền Bồ Tát",
                canonicalSource: "Kinh Hoa Nghiêm (Phẩm Phổ Hiền Hạnh Nguyện)",
                coreVirtue: "Đại Hạnh (Hành động kiên trì, thực thi các đại nguyện rộng lớn)",
                pureLand: "Núi Nga Mi / Thị giả hữu biên Phật Thích Ca",
                memorialDays: [
                    ILDeityMemorialDayEntity(lunarDay: 21, lunarMonth: 2, eventName: "Ngày Vía Đức Bồ Tát Phổ Hiền")
                ],
                iconography: ILDeityIconographyEntity(
                    posture: "Ngồi trang nghiêm trên lưng voi trắng sáu ngà",
                    mountOrThrone: "Voi trắng sáu ngà (Lục nha bạch tượng)",
                    sacredArtifacts: ["Cành hoa sen trắng hoặc gậy như ý", "Cuốn kinh sách báu"],
                    symbolicMeaning: "Voi trắng biểu trưng sức mạnh kiên trì nhẫn nại, sáu ngà tượng trưng cho Lục Độ Ba La Mật."
                ),
                biographySummary: "Đại diện cho sức mạnh thực hành lý tưởng Bồ Tát đạo trong cuộc sống thực tế. Trong Kinh Hoa Nghiêm, Ngài tuyên thuyết Mười Đại Nguyện Vương hướng dẫn Bồ Tát và chúng sinh quay về cõi Cực Lạc.",
                greatVows: [
                    "Nhất giả Lễ kính chư Phật, Nhị giả Xưng tán Như Lai, Tam giả Quảng tu cúng dường.",
                    "Hằng thuận chúng sinh, Phổ giai hồi hướng khắp mười phương pháp giới."
                ],
                mantra: ILDeityMantraEntity(
                    shortSanskrit: "Oṃ Samantabhadra Mahākaruṇā Hūṃ",
                    shortSinoVietnamese: "Án Tam Mãn Đa Bạt Đà La Hồng",
                    dharaniName: "Phổ Hiền Bồ Tát Căn Bản Chân Ngôn",
                    dharaniSnippet: "Nam mô tam mãn đa một đà nẫm, án ám hàm xoa đát đa bạt đà la tát bà ha."
                )
            ),
            ILDeityEntity(
                id: "bodhisattva_ksitigarbha",
                kind: .bodhisattva,
                nameVi: "Địa Tạng Vương Bồ Tát",
                nameSanskrit: "Kṣitigarbha Bodhisattva",
                nameChinese: "地藏王菩薩",
                titleHonorific: "Đại Nguyện Địa Tạng Vương Bồ Tát",
                canonicalSource: "Kinh Địa Tạng Bổn Nguyện Công Đức",
                coreVirtue: "Đại Nguyện (Nguyện lực cứu vớt chúng sinh nơi cõi u minh tối tăm)",
                pureLand: "Cõi U Minh / Núi Cửu Hoa Sơn",
                memorialDays: [
                    ILDeityMemorialDayEntity(lunarDay: 30, lunarMonth: 7, eventName: "Ngày Vía Bồ Tát Địa Tạng (Tháng thiếu tính ngày 29)")
                ],
                iconography: ILDeityIconographyEntity(
                    posture: "Hiện thân hình tướng một vị Tỳ-kheo đầu tròn xuất gia, nét mặt đại từ bi",
                    mountOrThrone: "Tòa sen hoặc cưỡi linh thú Đề Thính",
                    sacredArtifacts: ["Tích trượng cầm tay phải có 12 khoen", "Viên Như Ý Minh Châu trên tay trái"],
                    symbolicMeaning: "Tích trượng rung mở cánh cửa địa ngục si mê, ngọc minh châu chiếu sáng cõi u tối u minh."
                ),
                biographySummary: "Tiền thân là Quang Mục Nữ và Bà-la-môn Nữ hiếu thảo cứu mẹ khỏi chốn trầm luân. Trước Đức Thích Ca tại cung trời Đao Lợi, Ngài nhận lãnh phó chúc ở lại đời ác bảo bọc chúng sinh từ khi Thích Ca nhập diệt cho đến lúc Di Lặc ra đời.",
                greatVows: [
                    "Địa ngục vị không, thệ bất thành Phật (Địa ngục chưa trống rỗng, thề chưa thành Phật).",
                    "Chúng sinh độ tận, phương chứng Bồ Đề (Độ hết chúng sinh mới chứng đạo Bồ Đề)."
                ],
                mantra: ILDeityMantraEntity(
                    shortSanskrit: "Oṃ Ha Ha Ha Vismaye Svāhā",
                    shortSinoVietnamese: "Án Ha Ha Ha Vi Tư Ma Duệ Thoa Ha",
                    dharaniName: "Địa Tạng Bồ Tát Diệt Định Nghiệp Chân Ngôn",
                    dharaniSnippet: "Án bát la mạt lân đà nảnh ta bà ha."
                )
            ),
            ILDeityEntity(
                id: "bodhisattva_mahasthamaprapta",
                kind: .bodhisattva,
                nameVi: "Đại Thế Chí Bồ Tát",
                nameSanskrit: "Mahāsthāmaprāpta Bodhisattva",
                nameChinese: "大勢至菩薩",
                titleHonorific: "Đại Lực Đại Thế Chí Bồ Tát",
                canonicalSource: "Kinh Quán Vô Lượng Thọ, Kinh Lăng Nghiêm (Chương Niệm Phật Viên Thông)",
                coreVirtue: "Đại Lực (Ánh sáng trí tuệ uy dũng dứt trừ ách nạn)",
                pureLand: "Tây Phương Cực Lạc (Thị giả hữu biên Phật A Di Đà)",
                memorialDays: [
                    ILDeityMemorialDayEntity(lunarDay: 13, lunarMonth: 7, eventName: "Ngày Vía Đức Bồ Tát Đại Thế Chí")
                ],
                iconography: ILDeityIconographyEntity(
                    posture: "Đứng hoặc ngồi kiết già, trên vương miện có bảo bình chứa ánh sáng trí huệ",
                    mountOrThrone: "Tòa sen báu ngát hương",
                    sacredArtifacts: ["Cành hoa sen xanh (Thanh liên hoa)"],
                    symbolicMeaning: "Tượng trưng cho sự thanh tịnh vượt khỏi bùn nhơ thế tục và sức mạnh giải thoát kiên cố."
                ),
                biographySummary: "Cùng với Bồ Tát Quán Thế Âm hợp thành Tây Phương Tam Thánh. Ngài dùng ánh sáng trí tuệ chiếu khắp muôn loài, làm chấn động tam thiên đại thiên thế giới mỗi khi bước chân di chuyển, đưa chúng sinh lìa khỏi ba đường ác.",
                greatVows: [
                    "Tiếp dẫn người thực hành pháp môn Niệm Phật: Như con nhớ mẹ, tâm Phật tâm ta hòa làm một.",
                    "Dùng trí lực dũng mãnh dập tắt mọi lửa phiền não tham sân của chúng sinh."
                ],
                mantra: ILDeityMantraEntity(
                    shortSanskrit: "Oṃ Saṃ Jam Jaṃ Saḥ Svāhā",
                    shortSinoVietnamese: "Án Tán Nhiễm Nhiễm Tán Thoa Ha",
                    dharaniName: "Đại Thế Chí Bồ Tát Chân Ngôn",
                    dharaniSnippet: "Nam mô tam mãn đa một đà nẫm, án hàm hàm thọ đát hàm tát bà ha."
                )
            ),
            ILDeityEntity(
                id: "bodhisattva_cundi",
                kind: .bodhisattva,
                nameVi: "Chuẩn Đề Bồ Tát",
                nameSanskrit: "Cundī Bodhisattva",
                nameChinese: "準提菩薩",
                titleHonorific: "Thất Câu Chi Phật Mẫu Chuẩn Đề",
                canonicalSource: "Kinh Thất Câu Chi Phật Mẫu Sở Thuyết Chuẩn Đề Đà La Ni",
                coreVirtue: "Phật Mẫu Hộ Trì (Tâm từ bảo bọc vô lượng, tiêu tai diệt tội)",
                pureLand: "Chuẩn Đề Tịnh Cư / Bát Nhã Pháp Giới",
                memorialDays: [
                    ILDeityMemorialDayEntity(lunarDay: 16, lunarMonth: 3, eventName: "Ngày Vía Bồ Tát Chuẩn Đề")
                ],
                iconography: ILDeityIconographyEntity(
                    posture: "Ngồi kiết già trên đài sen, có 3 mắt và 18 cánh tay cầm các loại pháp khí khác nhau",
                    mountOrThrone: "Tòa sen ngự trên hồ nước đỡ bởi hai vị Long vương Nanda và Upananda",
                    sacredArtifacts: ["Kính báu Chuẩn Đề", "Kinh điển, hoa sen, tích trượng, bảo ấn, bình nước"],
                    symbolicMeaning: "18 cánh tay biểu trưng cho Thập Bát Bất Cộng Pháp của hàng giác ngộ tối thượng."
                ),
                biographySummary: "Được tôn xưng là Mẹ của bảy ức chư Phật (Thất Câu Chi Phật Mẫu). Thần chú của Ngài có sức uy lực vô biên giúp hành giả tại gia phá trừ chướng nạn, cầu đảo tốt lành và tu trì mau thành tựu phước huệ.",
                greatVows: [
                    "Bảo hộ người tu tại gia không bị tà ma quấy nhiễu, đời sống gia đình hòa hợp an khang.",
                    "Khiến người trì tụng tiêu trừ nghiệp tội nhiều đời, vãng sanh cõi Phật."
                ],
                mantra: ILDeityMantraEntity(
                    shortSanskrit: "Oṃ Cale Cule Cunde Svāhā",
                    shortSinoVietnamese: "Án Chiết Lệ Chủ Lệ Chuẩn Đề Thoa Ha",
                    dharaniName: "Chuẩn Đề Thần Chú",
                    dharaniSnippet: "Nam mô tát đa nẫm, tam miệu tam bồ đề, câu chi nẫm, đát điệt tha: Án, chiết lệ chủ lệ chuẩn đề ta bà ha."
                )
            ),
            ILDeityEntity(
                id: "bodhisattva_akashagarbha",
                kind: .bodhisattva,
                nameVi: "Hư Không Tạng Bồ Tát",
                nameSanskrit: "Ākāśagarbha Bodhisattva",
                nameChinese: "虛空藏菩薩",
                titleHonorific: "Đại Hư Không Tạng Bồ Tát",
                canonicalSource: "Kinh Hư Không Tạng Bồ Tát Sở Vấn",
                coreVirtue: "Trí Tuệ & Phước Đức Bao La Như Không Gian",
                pureLand: "Đại Trang Nghiêm Thế Giới",
                memorialDays: [
                    ILDeityMemorialDayEntity(lunarDay: 15, lunarMonth: 1, eventName: "Ngày Lễ Cầu Trí Tuệ Thượng Nguyên")
                ],
                iconography: ILDeityIconographyEntity(
                    posture: "Ngồi kiết già an định trên tòa hoa sen",
                    mountOrThrone: "Tòa sen báu",
                    sacredArtifacts: ["Gươm báu trí tuệ", "Ngọc Như Ý tỏa hào quang trên cành sen"],
                    symbolicMeaning: "Kho báu trí huệ và phước đức rộng lớn vô cùng vô tận như khoảng không hư không vũ trụ."
                ),
                biographySummary: "Là hiện thân của sự giàu có về công đức và trí tuệ tâm linh. Người cầu nguyện Ngài với lòng chí thành sẽ khai thông trí nhớ, tăng trưởng năng lực học tập và phá tan sự nghèo khó si mê.",
                greatVows: [
                    "Nguyện ban phát kho tàng Phật pháp vô tận cho những ai bần cùng khốn khó.",
                    "Giúp chúng sinh xua tan tội chướng, đạt được trí nhớ siêu đẳng (viên mãn trí)."
                ],
                mantra: ILDeityMantraEntity(
                    shortSanskrit: "Oṃ Ākāśagarbha Svāhā",
                    shortSinoVietnamese: "Án A Ca Xa Nga La Bà Thoa Ha",
                    dharaniName: "Hư Không Tạng Bồ Tát Trí Huệ Chân Ngôn",
                    dharaniSnippet: "Nam mô a ca xá yết bà gia, án a lị kế ma lị mô lị ta bà ha."
                )
            ),
            ILDeityEntity(
                id: "bodhisattva_vajrapani",
                kind: .bodhisattva,
                nameVi: "Kim Cương Thủ Bồ Tát",
                nameSanskrit: "Vajrapāṇi Bodhisattva",
                nameChinese: "金剛手菩薩",
                titleHonorific: "Bí Mật Chủ Kim Cương Thủ",
                canonicalSource: "Kinh Đại Nhật, Mật Tông Kim Cương Đỉnh Kinh",
                coreVirtue: "Hộ Pháp & Uy Lực Tối Thượng (Sức mạnh tiêu trừ ma chướng và chướng ngại nội tâm)",
                pureLand: "Liễu Đạt Mật Nghiêm Cõi Mật Tông",
                memorialDays: [
                    ILDeityMemorialDayEntity(lunarDay: 8, lunarMonth: 4, eventName: "Ngày Lễ Hộ Pháp Chư Thiên")
                ],
                iconography: ILDeityIconographyEntity(
                    posture: "Thân tướng uy nghiêm dũng mãnh, thế đứng chiến binh (Ấn Tiễn Đột)",
                    mountOrThrone: "Đạp trên phiến đá lửa hàng phục tà ma",
                    sacredArtifacts: ["Chày kim cương (Vajra) cầm chắc ở tay phải"],
                    symbolicMeaning: "Chày kim cương không thể bị phá vỡ, tượng trưng cho bản tính thực tại bất biến tiêu diệt si ám."
                ),
                biographySummary: "Là biểu hiện sức mạnh dũng mãnh của tất cả chư Phật mười phương. Ngài là thủ lĩnh của hàng Dạ-xoa hộ pháp, luôn theo sát hộ vệ người tu hành chánh đạo thoát khỏi sự quấy phá của ngoại ma và nội ma.",
                greatVows: [
                    "Nguyện bảo vệ mạng mạch chánh pháp và người thọ trì giáo lý Kim Cương Thừa.",
                    "Đập tan tà kiến, giải trừ mọi bùa chú ám hại và sự sợ hãi tột cùng."
                ],
                mantra: ILDeityMantraEntity(
                    shortSanskrit: "Oṃ Vajrapāṇi Hūṃ Phaṭ",
                    shortSinoVietnamese: "Án Phạt Chiết La Ba Ni Hồng Phấn",
                    dharaniName: "Kim Cương Thủ Hộ Pháp Đà La Ni",
                    dharaniSnippet: "Nam mô phạt chiết la noa gia, đát điệt tha: Án phạt chiết la hồng phát tra."
                )
            ),
            ILDeityEntity(
                id: "bodhisattva_tara_green",
                kind: .bodhisattva,
                nameVi: "Lục Độ Mẫu (Tara Xanh)",
                nameSanskrit: "Śyāmatārā (Green Tārā)",
                nameChinese: "綠度母",
                titleHonorific: "Thánh Cứu Độ Mẫu Tara Xanh",
                canonicalSource: "Tārā Mūla Tantra, Tán Tụng Hai Mươi Mốt Tán Thán Tara",
                coreVirtue: "Hành Động Cấp Thiết (Cứu nạn cấp kỳ, chở che tám nỗi sợ hãi lớn)",
                pureLand: "Diệu Nguyệt Thế Giới (Cõi Tịnh độ Núi Yarlung)",
                memorialDays: [
                    ILDeityMemorialDayEntity(lunarDay: 8, lunarMonth: 1, eventName: "Ngày Lễ Cầu Bình An Độ Mẫu")
                ],
                iconography: ILDeityIconographyEntity(
                    posture: "Ngồi bán già thế du hý, chân phải duỗi nhẹ xuống đất sẵn sàng đứng dậy cứu nạn",
                    mountOrThrone: "Tòa sen xanh ngọc",
                    sacredArtifacts: ["Cành sen xanh Utpala cầm nơi tay trái đặt ngang ngực"],
                    symbolicMeaning: "Tư thế sẵn sàng bật dậy cứu giúp chúng sinh ngay tức khắc khi có tiếng gọi chân thành."
                ),
                biographySummary: "Được sinh ra từ giọt nước mắt đại bi của Đức Quán Thế Âm khi nhìn thấy nỗi khổ của muôn loài. Ngài phát thệ nguyện mãi mãi giữ thân nữ nhân để hành trì Bồ Tát đạo và hóa độ chúng sinh cho đến ngày tận thế.",
                greatVows: [
                    "Cứu vớt chúng sinh khỏi 8 nỗi sợ hãi lớn: kiêu mạn, si mê, sân hận, ghen tị, tà kiến, tham lam, dục lạc, hoài nghi.",
                    "Mau chóng đáp ứng những lời thỉnh cầu lương thiện của chúng sinh trong tích tắc."
                ],
                mantra: ILDeityMantraEntity(
                    shortSanskrit: "Oṃ Tāre Tuttāre Ture Svāhā",
                    shortSinoVietnamese: "Án Đa Rê Đút Đa Rê Đu Rê Thoa Ha",
                    dharaniName: "Độ Mẫu Căn Bản Chân Ngôn",
                    dharaniSnippet: "Án đát nê đát nê đát nê, đát lệ tha bà ha."
                )
            ),
            ILDeityEntity(
                id: "bodhisattva_tara_white",
                kind: .bodhisattva,
                nameVi: "Bạch Độ Mẫu (Tara Trắng)",
                nameSanskrit: "Sitatārā (White Tārā)",
                nameChinese: "白度母",
                titleHonorific: "Trường Thọ Thánh Cứu Độ Mẫu",
                canonicalSource: "Kinh điển Mật Tạng Tạng Truyền",
                coreVirtue: "Trường Thọ & Chữa Lành (Ban thọ mạng dài lâu, an định thân tâm)",
                pureLand: "Thanh Tịnh Cực Lạc Giới",
                memorialDays: [
                    ILDeityMemorialDayEntity(lunarDay: 15, lunarMonth: 10, eventName: "Khóa Lễ Cầu Trường Thọ Dược Sư")
                ],
                iconography: ILDeityIconographyEntity(
                    posture: "Ngồi kiết già kim cương tuyệt đối, toàn thân sắc trắng như tuyết thanh khiết",
                    mountOrThrone: "Đài sen trắng nguyệt luân",
                    sacredArtifacts: ["Hoa sen trắng tám cánh vươn cao", "Có 7 mắt (3 mắt trên mặt, 4 mắt trong lòng bàn tay, bàn chân)"],
                    symbolicMeaning: "Bảy con mắt nhìn thấu suốt nỗi khổ đau ở khắp ba cõi mười phương không góc khuất."
                ),
                biographySummary: "Là một trong những hóa thân từ bi nhất của Bồ Tát Tara, đại diện cho năng lượng chữa lành dịu mát của tình mẫu tử. Ngài ban tặng tuổi thọ dài lâu cho những ai trì giới và chuyên tâm tu học phụng sự tha nhân.",
                greatVows: [
                    "Tăng trưởng thọ mạng và phúc đức cho hành giả để họ hoàn tất con đường tu đạo.",
                    "Xua đuổi bệnh tật nan y và cái chết bất đắc kỳ tử (tai nạn bất ngờ)."
                ],
                mantra: ILDeityMantraEntity(
                    shortSanskrit: "Oṃ Tāre Tuttāre Ture Mama Āyur-Jñāna-Puṇye Puṣṭiṃ Kuru Svāhā",
                    shortSinoVietnamese: "Án Đa Rê Đút Đa Rê Đu Rê Ma Ma A Giác Phổ Ni Bố Sĩ Đinh Cưu Lô Thoa Ha",
                    dharaniName: "Bạch Độ Mẫu Trường Thọ Chân Ngôn",
                    dharaniSnippet: "Án đa rê đút đa rê đu rê mama a dũa pu nê..."
                )
            ),
            ILDeityEntity(
                id: "bodhisattva_bhaisajyaraja",
                kind: .bodhisattva,
                nameVi: "Dược Vương Bồ Tát",
                nameSanskrit: "Bhaiṣajyarāja Bodhisattva",
                nameChinese: "藥王菩薩",
                titleHonorific: "Đại Dược Vương Bồ Tát",
                canonicalSource: "Kinh Diệu Pháp Liên Hoa (Phẩm Dược Vương Bồ Tát Bổn Sự)",
                coreVirtue: "Xả Thân Cầu Pháp & Trừ Bệnh (Liều thuốc xoa dịu độc chướng)",
                pureLand: "Thị giả Phật Dược Sư cõi Tịnh Lưu Ly",
                memorialDays: [
                    ILDeityMemorialDayEntity(lunarDay: 28, lunarMonth: 4, eventName: "Ngày Vía Đức Bồ Tát Dược Vương")
                ],
                iconography: ILDeityIconographyEntity(
                    posture: "Đứng trang nghiêm trên tòa sen, thân tỏa ánh sáng thuần tịnh",
                    mountOrThrone: "Tòa sen",
                    sacredArtifacts: ["Bình thuốc thần dược", "Cây thuốc thảo mộc trừ độc"],
                    symbolicMeaning: "Tượng trưng cho tinh thần hy sinh tận hiến và phương thuốc pháp vị tiêu trừ si mê."
                ),
                biographySummary: "Tiền thân là Nhất Thiết Chúng Sanh Hỷ Kiến Bồ Tát. Ngài đã từng uống hương dầu thơm và tự thiêu thân mình cúng dường Phật Nhật Nguyệt Tịnh Minh Đức để cầu chánh pháp, chứng đắc hiện nhất thiết sắc thân tam muội.",
                greatVows: [
                    "Nguyện làm vị lương y chữa trị mọi vết thương thể xác và tinh thần cho người đau khổ.",
                    "Ban phát giáo pháp như linh dược trị bệnh phiền não tận gốc rễ."
                ],
                mantra: ILDeityMantraEntity(
                    shortSanskrit: "Oṃ Bhaiṣajyarāja Svāhā",
                    shortSinoVietnamese: "Án Bệ Sát Xã La Xà Thoa Ha",
                    dharaniName: "Dược Vương Bồ Tát Trừ Bệnh Chân Ngôn",
                    dharaniSnippet: "Án bệ sát xã xà da xà da bệ sát xã ta bà ha."
                )
            ),
            ILDeityEntity(
                id: "bodhisattva_vajrasattva",
                kind: .bodhisattva,
                nameVi: "Kim Cương Tát Đỏa",
                nameSanskrit: "Vajrasattva Bodhisattva",
                nameChinese: "金剛薩埵",
                titleHonorific: "Đại Tịnh Hóa Kim Cương Tát Đỏa",
                canonicalSource: "Mật Tông Ngũ Bí Mật Nghi Quỹ, Phổ Hiền Hạnh Nguyện",
                coreVirtue: "Tịnh Hóa Nghiệp Chướng (Rửa sạch mọi giới nguyện ô uế và nghiệp ác)",
                pureLand: "Cõi Mật Nghiêm Kim Cương Cực Lạc",
                memorialDays: [
                    ILDeityMemorialDayEntity(lunarDay: 15, lunarMonth: 7, eventName: "Khóa Lễ Sám Hối & Tịnh Hóa")
                ],
                iconography: ILDeityIconographyEntity(
                    posture: "Ngồi kiết già an nhiên, thân màu trắng sáng chói rực rỡ như pha lê",
                    mountOrThrone: "Đài sen trăng sáng",
                    sacredArtifacts: ["Chày kim cương cầm ở tay phải trước ngực", "Chuông kim cương cầm ở tay trái bên hông"],
                    symbolicMeaning: "Chày tượng trưng cho Từ bi và Phương tiện thiện xảo; Chuông tượng trưng cho Trí tuệ Bát Nhã tánh không."
                ),
                biographySummary: "Là hiện thân của sự thanh tịnh nguyên sơ nơi tâm thức của tất cả chư Phật. Pháp môn thực hành trì tụng Bách Tự Minh Chân Ngôn (chú 100 chữ) của Ngài là phương pháp tối thượng để thanh lọc các nghiệp chướng xấu ác và khôi phục giới luật đã trót phạm.",
                greatVows: [
                    "Nguyện khi chưa tẩy sạch mọi tội ác, nghiệp xấu của kẻ chí tâm sám hối thì chưa chứng Phật quả.",
                    "Bảo hộ tâm thức của hành giả luôn duy trì trạng thái thuần khiết, không bị nhiễm trược."
                ],
                mantra: ILDeityMantraEntity(
                    shortSanskrit: "Oṃ Vajrasattva Hūṃ",
                    shortSinoVietnamese: "Án Phạt Chiết La Tát Đỏa Hồng",
                    dharaniName: "Bách Tự Minh Chân Ngôn (Mật Chú 100 Chữ Tịnh Hóa Nghiệp)",
                    dharaniSnippet: "Oṃ Vajrasattva samayam anupālaya, Vajrasattva tvenopatishṭha, Dṛḍho me bhava, Sutoṣyo me bhava, Supoṣyo me bhava, Anurakto me bhava, Sarva siddhiṃ me prayaccha..."
                )
            )
        ]
    }
}
