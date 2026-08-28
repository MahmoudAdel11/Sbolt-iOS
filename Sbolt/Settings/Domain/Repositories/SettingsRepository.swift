//
//  SettingsRepository.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Boundary between the domain and wherever settings live (mock today, a real
/// API/local store later). `save` returns the persisted settings.
protocol SettingsRepository {
    func loadSettings() async throws -> AppSettings
    func saveSettings(_ settings: AppSettings) async throws -> AppSettings
}
