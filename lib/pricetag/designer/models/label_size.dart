class LabelSize {
  final String name;
  final double widthMm;
  final double heightMm;
  final int dpi;

  const LabelSize({
    required this.name,
    required this.widthMm,
    required this.heightMm,
    required this.dpi,
  });

  /// Width in printer dots (pixels at given DPI)
  double get widthPx => widthMm / 25.4 * dpi;

  /// Height in printer dots (pixels at given DPI)
  double get heightPx => heightMm / 25.4 * dpi;

  /// Aspect ratio width/height
  double get aspectRatio => widthMm / heightMm;

  LabelSize copyWith({
    String? name,
    double? widthMm,
    double? heightMm,
    int? dpi,
  }) {
    return LabelSize(
      name: name ?? this.name,
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      dpi: dpi ?? this.dpi,
    );
  }

  static const presets = [
    LabelSize(name: '4×3 см',   widthMm: 40,  heightMm: 30, dpi: 203),
    LabelSize(name: '5×3 см',   widthMm: 50,  heightMm: 30, dpi: 203),
    LabelSize(name: '6×4 см',   widthMm: 60,  heightMm: 40, dpi: 203),
    LabelSize(name: '7×4 см',   widthMm: 70,  heightMm: 40, dpi: 203),
    LabelSize(name: '10×5 см',  widthMm: 100, heightMm: 50, dpi: 203),
    LabelSize(name: '10×6 см',  widthMm: 100, heightMm: 60, dpi: 203),
  ];

  Map<String, dynamic> toJson() => {
        'name': name,
        'widthMm': widthMm,
        'heightMm': heightMm,
        'dpi': dpi,
      };

  factory LabelSize.fromJson(Map<String, dynamic> json) => LabelSize(
        name: json['name'] as String,
        widthMm: (json['widthMm'] as num).toDouble(),
        heightMm: (json['heightMm'] as num).toDouble(),
        dpi: json['dpi'] as int,
      );

  @override
  bool operator ==(Object other) =>
      other is LabelSize &&
      other.widthMm == widthMm &&
      other.heightMm == heightMm &&
      other.dpi == dpi;

  @override
  int get hashCode => Object.hash(widthMm, heightMm, dpi);

  @override
  String toString() => 'LabelSize($name, ${widthMm}x${heightMm}mm, ${dpi}dpi)';
}
