public enum AccessibilityPreferences {
    public static func allowsMotion(reduceMotion: Bool) -> Bool {
        !reduceMotion
    }

    public static func surfaceOpacity(reduceTransparency: Bool) -> Double {
        reduceTransparency ? 1 : 0.92
    }
}
