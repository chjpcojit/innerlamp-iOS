//
//  ILEventsUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILEventsUseCase {
    func getEvents() -> ILEventsEntity
}

final class ILEventsUseCaseImpl: ILEventsUseCase {

    init() {}

    func getEvents() -> ILEventsEntity {
        // TODO: chưa có API sự kiện & khóa học được xác nhận — thay dữ liệu mẫu bên dưới bằng
        // ILEventsRepository → networkService khi có contract (dùng data-builder).
        ILEventsEntity(
            featured: ILEventsFeaturedEntity(
                id: "event.khoatu.motngay",
                day: "14",
                monthLabel: "events.month.sep".localized,
                title: "events.mock.featured.title".localized,
                meta: "events.mock.featured.meta".localized,
                seatsLeft: 12
            ),
            upcoming: [
                ILEventsEventEntity(
                    id: "event.vulan",
                    name: "events.mock.upcoming.0.name".localized,
                    subtitle: "events.mock.upcoming.0.sub".localized,
                    day: "15",
                    monthLabel: "events.month.sep".localized,
                    tone: .gold,
                    status: .open
                ),
                ILEventsEventEntity(
                    id: "event.hieudao",
                    name: "events.mock.upcoming.1.name".localized,
                    subtitle: "events.mock.upcoming.1.sub".localized,
                    day: "18",
                    monthLabel: "events.month.sep".localized,
                    tone: .green,
                    status: .open
                ),
                ILEventsEventEntity(
                    id: "event.batquantrai",
                    name: "events.mock.upcoming.2.name".localized,
                    subtitle: "events.mock.upcoming.2.sub".localized,
                    day: "22",
                    monthLabel: "events.month.sep".localized,
                    tone: .rose,
                    status: .closing(seatsLeft: 4)
                ),
                ILEventsEventEntity(
                    id: "event.phongsanh",
                    name: "events.mock.upcoming.3.name".localized,
                    subtitle: "events.mock.upcoming.3.sub".localized,
                    day: "30",
                    monthLabel: "events.month.sep".localized,
                    tone: .ink,
                    status: .open
                )
            ],
            courses: [
                ILEventsEventEntity(
                    id: "course.thiencanniem",
                    name: "events.mock.course.0.name".localized,
                    subtitle: "events.mock.course.0.sub".localized,
                    day: "8",
                    monthLabel: "events.month.week".localized,
                    tone: .green,
                    status: .open
                ),
                ILEventsEventEntity(
                    id: "course.kinhphapcu",
                    name: "events.mock.course.1.name".localized,
                    subtitle: "events.mock.course.1.sub".localized,
                    day: "6",
                    monthLabel: "events.month.week".localized,
                    tone: .gold,
                    status: .open
                ),
                ILEventsEventEntity(
                    id: "course.niemphat",
                    name: "events.mock.course.2.name".localized,
                    subtitle: "events.mock.course.2.sub".localized,
                    day: "4",
                    monthLabel: "events.month.week".localized,
                    tone: .rose,
                    status: .upcoming
                )
            ],
            registered: [
                ILEventsEventEntity(
                    id: "event.khoatu.motngay.reg",
                    name: "events.mock.registered.0.name".localized,
                    subtitle: "events.mock.registered.0.sub".localized,
                    day: "14",
                    monthLabel: "events.month.sep".localized,
                    tone: .green,
                    status: .registered
                ),
                ILEventsEventEntity(
                    id: "event.vulan.reg",
                    name: "events.mock.registered.1.name".localized,
                    subtitle: "events.mock.registered.1.sub".localized,
                    day: "15",
                    monthLabel: "events.month.sep".localized,
                    tone: .gold,
                    status: .registered
                )
            ]
        )
    }
}
