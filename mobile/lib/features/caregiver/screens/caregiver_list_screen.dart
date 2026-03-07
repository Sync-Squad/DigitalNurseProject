import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/caregiver_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/caregiver_model.dart';
import '../../../core/models/user_model.dart';

class CaregiverListScreen extends StatefulWidget {
  const CaregiverListScreen({super.key});

  @override
  State<CaregiverListScreen> createState() => _CaregiverListScreenState();
}

class _CaregiverListScreenState extends State<CaregiverListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCaregivers();
    });
  }

  Future<void> _loadCaregivers() async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser != null && currentUser.role == UserRole.patient) {
      final caregiverProvider = context.read<CaregiverProvider>();
      await caregiverProvider.loadCaregivers(currentUser.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final caregiverProvider = context.watch<CaregiverProvider>();
    final caregivers = caregiverProvider.caregivers;
    final isLoading = caregiverProvider.isLoading;
    final error = caregiverProvider.error;

    // Show loading state
    if (isLoading && caregivers.isEmpty) {
      return FScaffold(
        header: FHeader.nested(
          title: const Text('My Caregivers'),
          prefixes: [FHeaderAction.back(onPress: () => context.pop())],
          suffixes: [
            FHeaderAction(
              icon: const Icon(FIcons.plus),
              onPress: () => context.push('/caregiver/add'),
            ),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error state
    if (error != null && caregivers.isEmpty) {
      return FScaffold(
        header: FHeader.nested(
          title: const Text('My Caregivers'),
          prefixes: [FHeaderAction.back(onPress: () => context.pop())],
          suffixes: [
            FHeaderAction(
              icon: const Icon(FIcons.plus),
              onPress: () => context.push('/caregiver/add'),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FIcons.info,
                size: 64,
                color: context.theme.colors.destructive,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading caregivers',
                style: context.theme.typography.lg,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: context.theme.typography.sm,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FButton(onPress: _loadCaregivers, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return FScaffold(
      header: FHeader.nested(
        title: const Text('My Caregivers'),
        prefixes: [FHeaderAction.back(onPress: () => context.pop())],
        suffixes: [
          FHeaderAction(
            icon: const Icon(FIcons.plus),
            onPress: () async {
              await context.push('/caregiver/add');
              // Reload caregivers after returning from add screen
              if (mounted && currentUser != null) {
                await _loadCaregivers();
              }
            },
          ),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: _loadCaregivers,
        child: caregivers.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FIcons.users,
                          size: 64,
                          color: context.theme.colors.mutedForeground,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No caregivers added yet',
                          style: context.theme.typography.lg,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a caregiver to help manage your care',
                          style: context.theme.typography.sm,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FButton(
                          onPress: () => context.push('/caregiver/add'),
                          child: const Text('Add Caregiver'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: caregivers.length,
                itemBuilder: (context, index) {
                  final caregiver = caregivers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: context.theme.colors.primary
                                  .withValues(alpha: 0.2),
                              child: Text(
                                caregiver.name[0].toUpperCase(),
                                style: context.theme.typography.lg.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.theme.colors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    caregiver.name,
                                    style: context.theme.typography.base
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    caregiver.phone,
                                    style: context.theme.typography.sm,
                                  ),
                                  if (caregiver.relationship != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      caregiver.relationship!,
                                      style: context.theme.typography.xs
                                          .copyWith(
                                            color: context
                                                .theme
                                                .colors
                                                .mutedForeground,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            FBadge(
                              child: Text(_getStatusText(caregiver.status)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _getStatusText(CaregiverStatus status) {
    switch (status) {
      case CaregiverStatus.pending:
        return 'Pending';
      case CaregiverStatus.accepted:
        return 'Active';
      case CaregiverStatus.declined:
        return 'Declined';
    }
  }
}
