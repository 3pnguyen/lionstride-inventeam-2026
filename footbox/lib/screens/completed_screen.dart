import 'package:flutter/material.dart';
import 'package:FootBox/screens/home_screen.dart';

class CompletedScreen extends StatelessWidget {
  final String foot;
  final String scanData;

  const CompletedScreen({
    super.key,
    required this.foot,
    required this.scanData,
  });

  List<List<double>> _parseMatrixData() {
    // The ESP32 sends data as space-separated values
    // Data comes in COLUMN-MAJOR order: for each column, all 12 rows
    // We need to reorganize it into a 2D grid [row][column] for proper display
    
    List<String> values = scanData.trim().split(' ');
    
    int columnCount = 26;
    int rowCount = 12;
    
    // Create matrix as [row][column] for proper orientation
    List<List<double>> matrix = List.generate(
      rowCount, 
      (_) => List.filled(columnCount, 0.0)
    );
    
    int index = 0;
    // Data comes as: col0_row0, col0_row1, ..., col0_row11, col1_row0, col1_row1, ...
    for (int col = 0; col < columnCount; col++) {
      for (int row = 0; row < rowCount; row++) {
        if (index < values.length) {
          double value = double.tryParse(values[index]) ?? 0.0;
          matrix[row][col] = value;
          index++;
        }
      }
    }
    
    return matrix;
  }

  Color _getHeatmapColor(double value, double min, double max) {
    // Normalize value between 0 and 1
    double normalized = (max - min) > 0 ? (value - min) / (max - min) : 0.0;
    
    // Create a gradient from blue (cold/low) to red (hot/high)
    if (normalized < 0.25) {
      // Blue to Cyan
      return Color.lerp(Colors.blue, Colors.cyan, normalized * 4)!;
    } else if (normalized < 0.5) {
      // Cyan to Green
      return Color.lerp(Colors.cyan, Colors.green, (normalized - 0.25) * 4)!;
    } else if (normalized < 0.75) {
      // Green to Yellow
      return Color.lerp(Colors.green, Colors.yellow, (normalized - 0.5) * 4)!;
    } else {
      // Yellow to Red
      return Color.lerp(Colors.yellow, Colors.red, (normalized - 0.75) * 4)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    
    List<List<double>> matrix = _parseMatrixData();
    
    // Find min and max values for color scaling
    double minValue = double.infinity;
    double maxValue = double.negativeInfinity;
    
    for (var row in matrix) {
      for (var value in row) {
        if (!value.isNaN && !value.isInfinite) {
          if (value < minValue) minValue = value;
          if (value > maxValue) maxValue = value;
        }
      }
    }
    
    // If all values are the same, adjust range slightly
    if (minValue == maxValue) {
      minValue -= 1;
      maxValue += 1;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
        title: Text(
          '$foot Foot Scan',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Lexend',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: scanData.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.warning, size: 64, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'No scan data received',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lexend',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please try scanning again',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Lexend',
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Scan Complete!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                        fontFamily: 'Lexend',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Range: ${minValue.toStringAsFixed(1)}°F - ${maxValue.toStringAsFixed(1)}°F',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Lexend',
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Smooth interpolated heatmap
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 26 / 12, // 26 columns wide, 12 rows tall
                          child: CustomPaint(
                            painter: InterpolatedHeatmapPainter(
                              matrix: matrix,
                              minValue: minValue,
                              maxValue: maxValue,
                              getColor: _getHeatmapColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Color legend
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Temperature Scale',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Lexend',
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.blue,
                                  Colors.cyan,
                                  Colors.green,
                                  Colors.yellow,
                                  Colors.red,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${minValue.toStringAsFixed(1)}°F',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'Lexend',
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                              const Text(
                                'Cool',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'Lexend',
                                  color: Colors.black54,
                                ),
                              ),
                              const Text(
                                'Warm',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'Lexend',
                                  color: Colors.black54,
                                ),
                              ),
                              const Text(
                                'Hot',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'Lexend',
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                '${maxValue.toStringAsFixed(1)}°F',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'Lexend',
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Statistics
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Scan Statistics',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Lexend',
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard('Min Temp', '${minValue.toStringAsFixed(1)}°F', Colors.blue),
                              _buildStatCard('Max Temp', '${maxValue.toStringAsFixed(1)}°F', Colors.red),
                              _buildStatCard('Sensors', '312', Colors.green),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'Lexend',
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lexend',
            color: color,
          ),
        ),
      ],
    );
  }
}

// Custom painter for smooth interpolated heatmap
class InterpolatedHeatmapPainter extends CustomPainter {
  final List<List<double>> matrix; // matrix[row][column]
  final double minValue;
  final double maxValue;
  final Color Function(double value, double min, double max) getColor;

  InterpolatedHeatmapPainter({
    required this.matrix,
    required this.minValue,
    required this.maxValue,
    required this.getColor,
  });

  // Bilinear interpolation
  double _interpolate(double x, double y) {
    // x = column position, y = row position
    int x0 = x.floor();
    int y0 = y.floor();
    int x1 = (x0 + 1).clamp(0, matrix[0].length - 1);
    int y1 = (y0 + 1).clamp(0, matrix.length - 1);
    
    x0 = x0.clamp(0, matrix[0].length - 1);
    y0 = y0.clamp(0, matrix.length - 1);
    
    double fx = x - x0;
    double fy = y - y0;
    
    double v00 = matrix[y0][x0];
    double v10 = matrix[y0][x1];
    double v01 = matrix[y1][x0];
    double v11 = matrix[y1][x1];
    
    double v0 = v00 * (1 - fx) + v10 * fx;
    double v1 = v01 * (1 - fx) + v11 * fx;
    
    return v0 * (1 - fy) + v1 * fy;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const int upscaleFactor = 4; // 4x upscaling for smooth appearance
    final int cols = matrix[0].length; // 26 columns
    final int rows = matrix.length; // 12 rows
    
    final int width = cols * upscaleFactor;
    final int height = rows * upscaleFactor;
    
    final pixelWidth = size.width / width;
    final pixelHeight = size.height / height;
    
    for (int px = 0; px < width; px++) {
      for (int py = 0; py < height; py++) {
        // Map pixel position to matrix coordinates
        double mx = px / upscaleFactor; // column
        double my = py / upscaleFactor; // row
        
        // Interpolate value
        double value = _interpolate(mx, my);
        
        // Get color
        Color color = getColor(value, minValue, maxValue);
        
        // Draw pixel
        final paint = Paint()..color = color;
        canvas.drawRect(
          Rect.fromLTWH(
            px * pixelWidth,
            py * pixelHeight,
            pixelWidth + 0.5, // Slight overlap to prevent gaps
            pixelHeight + 0.5,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}