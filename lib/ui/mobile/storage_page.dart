import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../theme/app_theme.dart';
import '../common/section_card.dart';

class MobileStoragePage extends StatelessWidget {
  const MobileStoragePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('Storage & limits', style: AppText.wordmark(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.page, AppSpace.half, AppSpace.page, AppSpace.section),
        children: const [
          SectionCard(
            icon: Iconsax.document_upload,
            title: 'File limits',
            padding: EdgeInsets.only(bottom: AppSpace.half),
            child: Column(
              children: [
                IconBadgeRow(
                  icon: Iconsax.document_text,
                  title: 'Up to 2 GB per file',
                  subtitle: '4 GB per file with Telegram Premium.',
                ),
                IconBadgeRow(
                  icon: Iconsax.cloud,
                  title: 'No total storage cap',
                  subtitle:
                      'Upload as much as you like — Telegram doesn\'t cap your total storage.',
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpace.base),
          SectionCard(
            icon: Iconsax.shield_tick,
            title: 'Staying safe from Telegram\'s limits',
            padding: EdgeInsets.only(bottom: AppSpace.half),
            child: Column(
              children: [
                IconBadgeRow(
                  icon: Iconsax.arrange_square_2,
                  title: 'One file at a time',
                  subtitle:
                      'SannDrive uploads files one by one with a short pause between them — never in parallel.',
                ),
                IconBadgeRow(
                  icon: Iconsax.timer_1,
                  title: 'Automatic slow-down',
                  subtitle:
                      'If Telegram asks us to wait (FLOOD_WAIT), uploads pause and resume on their own. This keeps your account in good standing.',
                ),
                IconBadgeRow(
                  icon: Iconsax.warning_2,
                  title: 'Avoid mass-dumping files',
                  subtitle:
                      'Thousands of files in one go can still get an account temporarily limited. Add big libraries in smaller batches.',
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpace.base),
          SectionCard(
            icon: Iconsax.info_circle,
            title: 'Good to know',
            padding: EdgeInsets.only(bottom: AppSpace.half),
            child: IconBadgeRow(
              icon: Iconsax.key,
              title: 'Your Telegram account is the storage',
              subtitle:
                  'Files live in your own Telegram account — this isn\'t a separate backup. If the account is lost, the files go with it, so keep copies of anything irreplaceable.',
            ),
          ),
        ],
      ),
    );
  }
}
