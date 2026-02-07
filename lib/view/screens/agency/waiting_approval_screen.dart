import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/agency_provider.dart';

class WaitingApprovalScreen extends StatelessWidget {
  final Map<String, dynamic> agency;
  
  const WaitingApprovalScreen({
    super.key,
    required this.agency,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final agencyName = agency['agency_name']?.toString() ?? 
                      agency['name']?.toString() ?? 
                      'Agency';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Host center',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black, size: 22),
            onPressed: () {
              // Refresh to check if request was approved
              final agencyProvider = Provider.of<AgencyProvider>(context, listen: false);
              final agencyId = agency['id'] ?? agency['agency_id'];
              if (agencyId != null) {
                agencyProvider.refresh();
              }
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(size.width * 0.06),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: size.height * 0.05),
              
              // 404-style Illustration
              Stack(
                alignment: Alignment.center,
                children: [
                  // Left "4"
                  Positioned(
                    left: size.width * 0.1,
                    child: Container(
                      width: size.width * 0.25,
                      height: size.height * 0.25,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '4',
                          style: TextStyle(
                            fontSize: 120,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Character (Penguin-like with robe)
                  Container(
                    width: size.width * 0.35,
                    height: size.height * 0.3,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Body
                        Container(
                          width: size.width * 0.25,
                          height: size.height * 0.2,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        // Robe
                        Positioned(
                          bottom: 0,
                          child: Container(
                            width: size.width * 0.3,
                            height: size.height * 0.15,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF7B4FFF), Color(0xFF9C27B0)],
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(100),
                                bottomRight: Radius.circular(100),
                              ),
                            ),
                          ),
                        ),
                        // Turban
                        Positioned(
                          top: size.height * 0.02,
                          child: Container(
                            width: size.width * 0.2,
                            height: size.height * 0.08,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7B4FFF), Color(0xFF9C27B0)],
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ),
                        // Eyes
                        Positioned(
                          top: size.height * 0.08,
                          left: size.width * 0.08,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          top: size.height * 0.08,
                          right: size.width * 0.08,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Right "4"
                  Positioned(
                    right: size.width * 0.1,
                    child: Container(
                      width: size.width * 0.25,
                      height: size.height * 0.25,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE91E63), Color(0xFFFF6B9D)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '4',
                          style: TextStyle(
                            fontSize: 120,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // UFO with beam
                  Positioned(
                    top: size.height * 0.05,
                    child: Column(
                      children: [
                        // UFO
                        Container(
                          width: size.width * 0.2,
                          height: size.height * 0.08,
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.2),
                            border: Border.all(
                              color: const Color(0xFF7B4FFF),
                              width: 3,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7B4FFF).withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // Beam
                        Container(
                          width: size.width * 0.15,
                          height: size.height * 0.12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF7B4FFF).withOpacity(0.6),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: size.height * 0.04),
              
              // Agency Name
              Text(
                agencyName,
                style: TextStyle(
                  fontSize: size.width * 0.06,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: size.height * 0.02),
              
              // Waiting Message
              Text(
                'Waiting for approval',
                style: TextStyle(
                  fontSize: size.width * 0.045,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: size.height * 0.01),
              
              // Description
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
                child: Text(
                  'Your join request has been sent to the agency owner. Please wait for them to review and approve your request.',
                  style: TextStyle(
                    fontSize: size.width * 0.035,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
         ],
          ),
        ),
      ),
    );
  }
}

