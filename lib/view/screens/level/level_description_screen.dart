import 'package:flutter/material.dart';

class LevelDescriptionScreen extends StatelessWidget {
  const LevelDescriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0F0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D1810),
        elevation: 0,
        title: const Text(
          'Level Description',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF8B6914),
                  const Color(0xFFD4AF37),
                  const Color(0xFF8B6914),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD4AF37),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                // Header with wings decoration
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.keyboard_double_arrow_right,
                        color: Colors.white.withOpacity(0.7),
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Level description',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.keyboard_double_arrow_left,
                        color: Colors.white.withOpacity(0.7),
                        size: 30,
                      ),
                    ],
                  ),
                ),
                
                // Description Box
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D2416),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFF6B4423),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'When you send a gift worth 1 coin, you gain 1 piont of experience(Send lucky gifts only get 10% experience).\nAs the level inreases, theicon style will also change.',
                    style: TextStyle(
                      color: Color(0xFFCCAA88),
                      fontSize: 15,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Table
                Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D1810),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      // Table Header
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF3D2416),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildHeaderCell('Grade'),
                            _buildHeaderCell('Accumulated\nexperience'),
                            _buildHeaderCell('Experience\nrequired'),
                          ],
                        ),
                      ),
                      
                      // Table Rows
                      _buildTableRow('Lv1-Lv5', '1-120k', 'Each level requires\nexperience 2.9k-3k'),
                      _buildTableRow('Lv5-Lv11', '120k-450k', 'Each level requires\nexperience 6k'),
                      _buildTableRow('Lv11-Lv13', '450k-1.23M', 'Each level requires\nexperience 390k'),
                      _buildTableRow('Lv14-Lv16', '1.23M-3.66M', 'Each level requires\nexperience 1M'),
                      _buildTableRow('Lv17-Lv18', '3.66M-6M', 'Each level requires\nexperience 1.3M'),
                      _buildTableRow('Lv18-Lv19', '6M-7.32M', 'Each level requires\nexperience 4.8M'),
                      _buildTableRow('Lv19-Lv25', '7.32M-29.37M', 'Each level requires\nexperience 3.45M'),
                      _buildTableRow('Lv25-Lv28', '29.37M-46.62M', 'Each level requires\nexperience 6.9M'),
                      _buildTableRow('Lv28-Lv33', '46.62M-136.32M', 'Each level requires\nexperience 20.7M'),
                      _buildTableRow('Lv33-Lv38', '136.32M-349.02M', 'Each level requires\nexperience 48M'),
                      _buildTableRow('Lv38-Lv39', '349.02M-397.02M', 'Each level requires\nexperience 136.8M'),
                      _buildTableRow('Lv39-Lv48', '397.02M-1110M', 'Each level requires\nexperience 72M'),
                      _buildTableRow('Lv48-Lv49', '1110M-1182M', 'Each level requires\nexperience 138M'),
                      _buildTableRow('Lv49-Lv58', '1182M-1925M', 'Each level requires\nexperience 75.6M'),
                      _buildTableRow('Lv58-Lv59', '1925M-2086M', 'Each level requires\nexperience 161M'),
                      _buildTableRow('Lv59-Lv68', '2086M-3536M', 'Each level requires\nexperience 145M'),
                      _buildTableRow('Lv68-Lv69', '3536M-3826M', 'Each level requires\nexperience 290M'),
                      _buildTableRow('Lv69-Lv78', '3826M-6451M', 'Each level requires\nexperience 262.5M'),
                      _buildTableRow('Lv78-Lv79', '6451M-6986M', 'Each level requires\nexperience 535M'),
                      _buildTableRow('Lv79-Lv88', '6986M-11771M', 'Each level requires\nexperience 478.5M'),
                      _buildTableRow('Lv88-Lv89', '11771M-12771M', 'Each level requires\nexperience 1000M'),
                      _buildTableRow('Lv89-Lv98', '12771M-21771M', 'Each level requires\nexperience 900M'),
                      _buildTableRow('Lv98-Lv99', '21771M-23571M', 'Each level requires\nexperience 1800M'),
                      _buildTableRow('Lv99-Lv100', '23571M-25000M', 'Each level requires\nexperience 1429M', isLast: true),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: Color(0xFF6B4423), width: 1),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(String grade, String accumulated, String required, {bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast 
              ? BorderSide.none 
              : const BorderSide(color: Color(0xFF6B4423), width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildTableCell(grade),
          _buildTableCell(accumulated),
          _buildTableCell(required),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: Color(0xFF6B4423), width: 1),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFCCAA88),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}