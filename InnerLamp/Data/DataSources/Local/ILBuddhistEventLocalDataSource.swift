//
//  ILBuddhistEventLocalDataSource.swift
//  InnerLamp
//

import CoreData
import Foundation

/// Reads the stored Buddhist event templates from Core Data, seeding the store on first use.
///
/// Sits between `ILBuddhistEventRepositoryImpl` and `CoreDataStack`. This type owns everything that
/// is actually Core Data — the fetch request, the `ILBuddhistEventTemplateMO` mapping, and the
/// seeding — so that `ILBuddhistEventTemplateMO` never appears outside this file and
/// `Data/Repositories/` needs no `CoreData` import.
///
/// The seed catalog is static content (the recurring Buddhist holidays), stored once per template id and kept in sync
/// on every read. Seeding is idempotent: a second fetch inserts nothing and changes nothing.
///
/// `nonisolated` for the same reason as `CoreDataStack`: these methods run on the background
/// context's queue.
nonisolated protocol ILBuddhistEventLocalDataSource {

    /// Every template, seeding first when the store is empty.
    func fetchTemplates() async throws -> [ILBuddhistEventTemplateEntity]
}

nonisolated final class ILBuddhistEventLocalDataSourceImpl: ILBuddhistEventLocalDataSource {

    private let stack: CoreDataStack

    init(stack: CoreDataStack) {
        self.stack = stack
    }

    func fetchTemplates() async throws -> [ILBuddhistEventTemplateEntity] {
        try await stack.performBackgroundTask { context in
            try Self.seedIfNeeded(in: context)
            return try Self.fetchManaged(in: context).map(Self.makeEntity(from:))
        }
    }

    // MARK: - Seeding

    /// Brings the store in line with the catalog: inserts templates whose `id` is not stored yet
    /// (fresh store, or templates added in a later app version) and rewrites the fields of the ones
    /// that are, so a changed field such as `category` reaches existing installs. Rows whose id is
    /// no longer in the catalog are left alone. Idempotent — a second call changes nothing.
    /// `performBackgroundTask` saves the context after `block` returns, so the changes here are
    /// persisted without an explicit `save`.
    private static func seedIfNeeded(in context: NSManagedObjectContext) throws {
        let stored = Dictionary(
            try fetchManaged(in: context).map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        for seed in seedTemplates {
            let managed = stored[seed.id] ?? ILBuddhistEventTemplateMO(context: context)
            apply(seed, to: managed)
        }
    }

    /// The recurring Buddhist holidays shown on the calendar. Content data (Vietnamese), not UI
    /// chrome — the same shape a remote catalog would return. See `AGENTS.md` for why this lives in
    /// the Data layer rather than the Domain layer.
    private static let seedTemplates: [ILBuddhistEventTemplateEntity] = [
        ILBuddhistEventTemplateEntity(
            id: "phat-dan", title: "Đại lễ Phật Đản",
            eventDescription: "Kỷ niệm ngày Đức Phật đản sinh, thành đạo và nhập Niết-bàn.",
            lunarDay: 15, lunarMonth: 4, tradition: .universal, category: .major, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "vesak", title: "Đại lễ Vesak",
            eventDescription: "Lễ Tam Hợp kỷ niệm Đản sinh, Thành đạo và Nhập Niết-bàn theo truyền thống Nam tông.",
            lunarDay: 15, lunarMonth: 4, tradition: .theravada, category: .major, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "vu-lan", title: "Đại lễ Vu Lan Báo Hiếu",
            eventDescription: "Mùa báo hiếu công ơn cha mẹ, cầu nguyện cho người thân đã khuất.",
            lunarDay: 15, lunarMonth: 7, tradition: .mahayana, category: .major, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "thanh-dao", title: "Lễ Phật Thành Đạo",
            eventDescription: "Kỷ niệm ngày Đức Phật thành đạo dưới cội bồ đề.",
            lunarDay: 8, lunarMonth: 12, tradition: .mahayana, category: .major, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "tet-nguyen-dan", title: "Tết Nguyên Đán",
            eventDescription: "Ngày đầu năm âm lịch — mừng năm mới và cầu an.",
            lunarDay: 1, lunarMonth: 1, tradition: .universal, category: .folk, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "ram-thang-gieng", title: "Rằm tháng Giêng",
            eventDescription: "Lễ cầu an đầu năm, dâng hương cầu quốc thái dân an.",
            lunarDay: 15, lunarMonth: 1, tradition: .universal, category: .major, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "phat-nhap-niet-ban", title: "Lễ Phật Nhập Niết-bàn",
            eventDescription: "Kỷ niệm ngày Đức Phật nhập Vô dư Niết-bàn.",
            lunarDay: 15, lunarMonth: 2, tradition: .mahayana, category: .major, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "quan-am-dan-sinh", title: "Vía Quán Thế Âm Đản sinh",
            eventDescription: "Kỷ niệm ngày đản sinh Bồ Tát Quán Thế Âm.",
            lunarDay: 19, lunarMonth: 2, tradition: .mahayana, category: .major, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "quan-am-thanh-dao", title: "Vía Quán Thế Âm Thành đạo",
            eventDescription: "Kỷ niệm ngày Bồ Tát Quán Thế Âm thành đạo.",
            lunarDay: 19, lunarMonth: 6, tradition: .mahayana, category: .major, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "quan-am-xuat-gia", title: "Vía Quán Thế Âm Xuất gia",
            eventDescription: "Kỷ niệm ngày Bồ Tát Quán Thế Âm xuất gia.",
            lunarDay: 19, lunarMonth: 9, tradition: .mahayana, category: .major, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "dia-tang", title: "Vía Địa Tạng Bồ Tát",
            eventDescription: "Kỷ niệm ngày vía Bồ Tát Địa Tạng, đấng cứu độ chúng sinh nơi địa ngục.",
            lunarDay: 30, lunarMonth: 7, tradition: .mahayana, category: .commemoration, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "a-di-da", title: "Vía Phật A Di Đà",
            eventDescription: "Kỷ niệm ngày đản sinh Phật A Di Đà, giáo chủ cõi Tây phương Cực lạc.",
            lunarDay: 17, lunarMonth: 11, tradition: .mahayana, category: .commemoration, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "magha-puja", title: "Lễ Magha Puja",
            eventDescription: "Kỷ niệm ngày 1.250 vị A-la-hán tự họp về nghe Phật thuyết giảng.",
            lunarDay: 15, lunarMonth: 3, tradition: .theravada, category: .commemoration, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "asalha-puja", title: "Lễ Asalha Puja",
            eventDescription: "Kỷ niệm ngày Đức Phật chuyển pháp luân lần đầu.",
            lunarDay: 15, lunarMonth: 8, tradition: .theravada, category: .commemoration, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "kathina", title: "Lễ dâng y Kathina",
            eventDescription: "Lễ dâng y sau mùa an cư của chư Tăng Nam tông.",
            lunarDay: 15, lunarMonth: 11, tradition: .theravada, category: .commemoration, isLeapMonthEligible: false
        ),
        // Vía / commemoration days from the design handoff (`LEVENTS` in the prototype) that the
        // original seed omitted.
        ILBuddhistEventTemplateEntity(
            id: "di-lac", title: "Vía Đức Di Lặc",
            eventDescription: "Kỷ niệm ngày vía Đức Phật Di Lặc, vị Phật tương lai.",
            lunarDay: 1, lunarMonth: 1, tradition: .mahayana, category: .commemoration, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "thich-ca-xuat-gia", title: "Đức Phật Thích Ca xuất gia",
            eventDescription: "Kỷ niệm ngày Đức Phật Thích Ca rời hoàng cung xuất gia tìm đạo.",
            lunarDay: 8, lunarMonth: 2, tradition: .mahayana, category: .commemoration, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "pho-hien", title: "Vía Phổ Hiền Bồ Tát",
            eventDescription: "Kỷ niệm ngày vía Bồ Tát Phổ Hiền, tượng trưng cho hạnh nguyện rộng lớn.",
            lunarDay: 21, lunarMonth: 2, tradition: .mahayana, category: .commemoration, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "van-thu", title: "Vía Văn Thù Bồ Tát",
            eventDescription: "Kỷ niệm ngày vía Bồ Tát Văn Thù, tượng trưng cho trí tuệ.",
            lunarDay: 4, lunarMonth: 4, tradition: .mahayana, category: .commemoration, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "an-cu-kiet-ha", title: "Khai kỳ An cư kiết hạ",
            eventDescription: "Ngày bắt đầu mùa an cư kiết hạ ba tháng của chư Tăng.",
            lunarDay: 16, lunarMonth: 4, tradition: .mahayana, category: .commemoration, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "dai-the-chi", title: "Vía Đại Thế Chí Bồ Tát",
            eventDescription: "Kỷ niệm ngày vía Bồ Tát Đại Thế Chí, tượng trưng cho ánh sáng trí tuệ.",
            lunarDay: 13, lunarMonth: 7, tradition: .mahayana, category: .commemoration, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "nhien-dang", title: "Vía Nhiên Đăng Cổ Phật",
            eventDescription: "Kỷ niệm ngày vía Phật Nhiên Đăng, vị Phật đã thọ ký cho Đức Thích Ca.",
            lunarDay: 22, lunarMonth: 8, tradition: .mahayana, category: .commemoration, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "duoc-su", title: "Vía Phật Dược Sư",
            eventDescription: "Kỷ niệm ngày vía Phật Dược Sư, giáo chủ cõi Đông phương Lưu Ly.",
            lunarDay: 30, lunarMonth: 9, tradition: .mahayana, category: .commemoration, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "dat-ma", title: "Vía Đạt Ma Tổ Sư",
            eventDescription: "Kỷ niệm ngày vía Đạt Ma Tổ Sư, Sơ tổ Thiền tông Trung Hoa.",
            lunarDay: 5, lunarMonth: 10, tradition: .mahayana, category: .commemoration, isLeapMonthEligible: false
        ),
        // Traditional Vietnamese festival days (folk, not strictly Buddhist) — kept as `.universal`
        // because the calendar surface is shared, mirroring how `tet-nguyen-dan` is already seeded.
        ILBuddhistEventTemplateEntity(
            id: "han-thuc", title: "Tết Hàn Thực",
            eventDescription: "Ngày tưởng nhớ tổ tiên, ăn bánh trôi bánh chay.",
            lunarDay: 3, lunarMonth: 3, tradition: .universal, category: .folk, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "doan-ngo", title: "Tết Đoan Ngọ",
            eventDescription: "Ngày diệt sâu bọ, cầu sức khỏe giữa năm.",
            lunarDay: 5, lunarMonth: 5, tradition: .universal, category: .folk, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "trung-thu", title: "Tết Trung Thu",
            eventDescription: "Tết trông trăng, đoàn viên và vui chơi của thiếu nhi.",
            lunarDay: 15, lunarMonth: 8, tradition: .universal, category: .folk, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "trung-cuu", title: "Tết Trùng Cửu",
            eventDescription: "Ngày tưởng nhớ ông bà tổ tiên, còn gọi là Tết Trùng Dương.",
            lunarDay: 9, lunarMonth: 9, tradition: .universal, category: .folk, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "ha-nguyen", title: "Tết Hạ Nguyên",
            eventDescription: "Rằm tháng Mười — lễ cúng tạ ơn sau vụ mùa.",
            lunarDay: 15, lunarMonth: 10, tradition: .universal, category: .folk, isLeapMonthEligible: false
        ),
        ILBuddhistEventTemplateEntity(
            id: "ong-cong-ong-tao", title: "Tết Ông Công Ông Táo",
            eventDescription: "Ngày đưa Táo quân về trời, dọn dẹp đón năm mới.",
            lunarDay: 23, lunarMonth: 12, tradition: .universal, category: .folk, isLeapMonthEligible: false
        )
    ]

    // MARK: - Query

    private static func fetchManaged(in context: NSManagedObjectContext) throws -> [ILBuddhistEventTemplateMO] {
        let request = NSFetchRequest<ILBuddhistEventTemplateMO>(entityName: ILBuddhistEventTemplateMO.entityName)
        request.sortDescriptors = [
            NSSortDescriptor(key: "lunarMonth", ascending: true),
            NSSortDescriptor(key: "lunarDay", ascending: true)
        ]
        return try context.fetch(request)
    }

    // MARK: - Mapping

    private static func apply(_ entity: ILBuddhistEventTemplateEntity, to managed: ILBuddhistEventTemplateMO) {
        managed.id = entity.id
        managed.title = entity.title
        managed.eventDescription = entity.eventDescription
        managed.lunarDay = Int16(entity.lunarDay)
        managed.lunarMonth = Int16(entity.lunarMonth)
        managed.tradition = entity.tradition.rawValue
        managed.category = entity.category.rawValue
        managed.isLeapMonthEligible = entity.isLeapMonthEligible
    }

    private static func makeEntity(from managed: ILBuddhistEventTemplateMO) -> ILBuddhistEventTemplateEntity {
        ILBuddhistEventTemplateEntity(
            id: managed.id,
            title: managed.title,
            eventDescription: managed.eventDescription,
            lunarDay: Int(managed.lunarDay),
            lunarMonth: Int(managed.lunarMonth),
            tradition: ILBuddhistTradition(rawValue: managed.tradition) ?? .universal,
            category: ILBuddhistEventCategory(rawValue: managed.category) ?? .commemoration,
            isLeapMonthEligible: managed.isLeapMonthEligible
        )
    }
}
