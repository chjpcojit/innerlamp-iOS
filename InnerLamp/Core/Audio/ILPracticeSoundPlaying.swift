//
//  ILPracticeSoundPlaying.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import Foundation

/// Plays the short sounds used by the practice screens (the "Chuông mõ" bell + wooden fish and the
/// "Tràng hạt" bead counter).
///
/// Defined as a Foundation-only protocol so ViewModels can depend on it without importing
/// UIKit / AVFoundation, keeping the ViewModel layer framework-free and unit-testable. The real
/// implementation (backed by `AVAudioPlayer`) lives in `ILPracticeSoundPlayer`.
protocol ILPracticeSoundPlaying {
    /// Play the wooden-fish ("mõ") strike sound.
    func playMo()
    /// Play the temple-bell ("chuông") strike sound.
    func playBell()
    /// Play the soft bead "click" for counting a single bead on the mala strand.
    func playBead()
}
