import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/provider/cp_toggle_provider.dart';

class CpPeriodToggleWidget extends StatelessWidget {
  final Function(CpPeriodType)? onCpPeriodChanged;

  const CpPeriodToggleWidget({super.key, this.onCpPeriodChanged});

  @override
  Widget build(BuildContext context) {
    return Consumer<CpPeriodToggleProvider>(
      builder: (context, provider, child) {
        return 
        
        LayoutBuilder(
          builder: (context, constraints) {
            const margin = 4.0;
            final containerWidth = constraints.maxWidth;
            final segmentWidth = (containerWidth-(margin*4)) / 2;

            return Container(
             
            
              //decoration: BoxDecoration(
              // color: Colors.black.withOpacity(0.3),
              //  borderRadius: BorderRadius.circular(30),
               // border: Border.all(color: const Color(0xffac8a78), width: 1.5),
             // ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                Stack(children: [
                  Image.asset("assets/images/toggle_cp.png",width:segmentWidth,),
Positioned(top:5,left:0,bottom:-5,right:0,child:_buildOption(
                        context,
                        title: 'Cp Wall',
                        period: CpPeriodType.CpWall,
                        provider: provider,
                      ),)

                ]),
                

                 Stack(children: [
                Image.asset("assets/images/toggle_cp.png",width:segmentWidth,),
                Positioned(top:5,left:0,bottom:-5,right:0,child:
_buildOption(
                        context,
                        title: 'Ranking',
                        period: CpPeriodType.Ranking,
                        provider: provider,
                      ),
                )
                 ])
              ],)
              
            );
          },
        );
      },
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String title,
    required CpPeriodType period,
    required CpPeriodToggleProvider provider,
  }) {
    final isSelected = provider.selectedPeriod == period;

    return  GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          provider.setPeriod(period);
          onCpPeriodChanged?.call(period);
        },
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? const Color.fromARGB(255, 195, 36, 150)
                  : const Color.fromARGB(255, 255, 255, 255),
            ),
          ),
        ),
      
    );
  }
}
