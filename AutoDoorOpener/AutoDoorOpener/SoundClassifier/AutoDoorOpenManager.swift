//
//  AutoDoorOpenManager.swift
//  AutoDoorOpener
//
//  Created by VI_Business on 10.10.22.
//

import Foundation
import RxBluetoothKit
import RxSwift
import Combine
import SoundAnalysis
import CoreBluetooth

class AutoDoorOpenManager {
    /// Indicates the amount of audio, in seconds, that informs a prediction.
    static let inferenceWindowSize = Double(1.5)
    /// The amount of overlap between consecutive analysis windows.
    ///
    /// The system performs sound classification on a window-by-window basis. The system divides an
    /// audio stream into windows, and assigns labels and confidence values. This value determines how
    /// much two consecutive windows overlap. For example, 0.9 means that each window shares 90% of
    /// the audio that the previous window uses.
    static let overlapFactor = Double(0.9)
    
    var detectorDisposeBag = Set<AnyCancellable>()
    var disposeBag = DisposeBag()
    
    let classificationSubject = PassthroughSubject<SNClassificationResult, Error>()
    static let trackedClassifications = [
        "bell",
        "telephone",
        "door_bell",
        "telephone_bell_ringing"
    ]
    
    let bleManager = CentralManager(queue: .main)
    static let openBleServiceId = "cba20d00-224d-11e6-9fb8-0002a5d5c51b"
    static let openBleCharacteristicId = "cba20002-224d-11e6-9fb8-0002a5d5c51b"
    static let openBlePayload: [UInt8] = [0x57, 0x01, 0x00]
    
    func start() {
        detectorDisposeBag.removeAll()
        disposeBag = DisposeBag()
        
        SystemAudioClassifier.singleton.startSoundClassification(
          subject: classificationSubject,
          inferenceWindowSize: Self.inferenceWindowSize,
          overlapFactor: Self.overlapFactor)
        
        classificationSubject.tryFilter { res in
            return !res.classifications
                .filter { $0.confidence > 0.5 && Self.trackedClassifications.contains($0.identifier) }
                .isEmpty
        }
        .throttle(for: .seconds(10), scheduler: RunLoop.main, latest: false)
        .sink(receiveCompletion: { _ in }) { [weak self] _ in
            self?.runDoorOpen()
        }.store(in: &detectorDisposeBag)
    }
    
    func stop() {
        detectorDisposeBag.removeAll()
        disposeBag = DisposeBag()
        
        SystemAudioClassifier.singleton.stopSoundClassification()
    }
    
    func runDoorOpen() {
        disposeBag = DisposeBag()
        openDoorObservable().take(1).subscribe().disposed(by: disposeBag)
    }
    
    func openDoorObservable() -> Observable<Void> {
        return bleManager.scanForPeripherals(withServices: [.init(string: Self.openBleServiceId)])
            .take(1)
            .flatMap { $0.peripheral.establishConnection() }
            .flatMap { $0.discoverServices([.init(string: Self.openBleServiceId)]) }.asObservable()
            .flatMap { Observable.from($0) }
            .flatMap { $0.discoverCharacteristics([.init(string: Self.openBleCharacteristicId)]) }.asObservable()
            .map { $0.first! }
            .flatMap { $0.writeValue(Data(Self.openBlePayload), type: CBCharacteristicWriteType.withResponse) }.asObservable()
            .map {_ in }
            .asObservable()
    }
}
