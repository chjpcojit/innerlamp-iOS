//
//  ILFamilyTreeTestFactory.swift
//  InnerLampTests
//

import Foundation
@testable import InnerLamp

/// The 24-person sample clan from the "Gia Pha Mobile" design prototype: founder `p1` with spouse
/// `s1`, six generations, clan head `p13` (with spouse `s2`).
enum ILFamilyTreeTestFactory {

    private static func member(
        _ id: String, _ name: String, _ gender: ILFamilyGender, born: Int?, died: Int? = nil,
        parent: String? = nil, spouse: String? = nil, head: Bool = false,
        anniversary: (day: Int, month: Int)? = nil, note: String? = nil
    ) -> ILFamilyMemberEntity {
        ILFamilyMemberEntity(
            id: id, name: name, gender: gender, birthYear: born, deathYear: died,
            anniversary: anniversary.map { ILFamilyLunarDate(day: $0.day, month: $0.month) },
            note: note, parentID: parent, spouseID: spouse, isClanHead: head
        )
    }

    static let members: [ILFamilyMemberEntity] = [
        member("p1", "Nguyễn Hữu Phúc", .male, born: 1812, died: 1879, anniversary: (15, 12), note: "Lập ấp Hành Thiện."),
        member("s1", "Lê Thị Hiền", .female, born: 1818, died: 1885, spouse: "p1", anniversary: (3, 8)),
        member("p2", "Nguyễn Hữu Lộc", .male, born: 1838, died: 1901, parent: "p1"),
        member("p3", "Nguyễn Hữu Thọ", .male, born: 1842, died: 1910, parent: "p1"),
        member("p4", "Nguyễn Hữu Tài", .male, born: 1864, died: 1932, parent: "p2"),
        member("p5", "Nguyễn Hữu Đức", .male, born: 1868, died: 1940, parent: "p2"),
        member("p6", "Nguyễn Hữu Nghĩa", .male, born: 1870, died: 1945, parent: "p3"),
        member("p7", "Nguyễn Thị Nhàn", .female, born: 1874, died: 1950, parent: "p3"),
        member("p8", "Nguyễn Hữu Khang", .male, born: 1890, died: 1962, parent: "p4"),
        member("p9", "Nguyễn Hữu An", .male, born: 1894, died: 1968, parent: "p4"),
        member("p10", "Nguyễn Hữu Bình", .male, born: 1899, died: 1972, parent: "p5"),
        member("p11", "Nguyễn Hữu Trí", .male, born: 1901, died: 1979, parent: "p6"),
        member("p12", "Nguyễn Thị Lan", .female, born: 1905, died: 1988, parent: "p6"),
        member("p13", "Nguyễn Hữu Minh", .male, born: 1946, parent: "p8", head: true, note: "Giữ nhà thờ tổ."),
        member("s2", "Trần Thị Hạnh", .female, born: 1950, spouse: "p13"),
        member("p14", "Nguyễn Hữu Hòa", .male, born: 1938, died: 2011, parent: "p9"),
        member("p15", "Nguyễn Thị Mai", .female, born: 1942, died: 2019, parent: "p10"),
        member("p16", "Nguyễn Hữu Tuấn", .male, born: 1935, died: 2008, parent: "p11"),
        member("p17", "Nguyễn Hữu Dũng", .male, born: 1940, died: 2016, parent: "p11"),
        member("p18", "Nguyễn Hữu Nam", .male, born: 1972, parent: "p13"),
        member("p19", "Nguyễn Thị Thu", .female, born: 1976, parent: "p13"),
        member("p20", "Nguyễn Hữu Khôi", .male, born: 1965, parent: "p14"),
        member("p21", "Nguyễn Hữu Phong", .male, born: 1962, parent: "p16"),
        member("p22", "Nguyễn Hữu Quang", .male, born: 1968, parent: "p17")
    ]

    static let tree = ILFamilyTreeEntity(clanName: "Họ Nguyễn Hữu", hometown: "Hành Thiện", members: members)

    static var graph: ILFamilyTreeGraph { ILFamilyTreeGraph(members: members) }

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}
