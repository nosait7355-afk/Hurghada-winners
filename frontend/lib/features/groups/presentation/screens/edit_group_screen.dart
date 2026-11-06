import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/groups/domain/entities/group_entity.dart';
import 'package:hurghada_winners/features/groups/presentation/providers/groups_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditGroupScreen extends ConsumerStatefulWidget {
  final GroupEntity group;

  const EditGroupScreen({super.key, required this.group});

  @override
  ConsumerState<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends ConsumerState<EditGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _capacityController;

  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _capacityController =
        TextEditingController(text: widget.group.capacity?.toString() ?? '');
    _isActive = widget.group.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // الرياضة غير قابلة للتعديل — لا تُرسَل إطلاقاً (المجموعة تبقى في رياضتها).
    final error = await ref.read(groupsProvider.notifier).updateGroup(
          id: widget.group.id,
          name: _nameController.text.trim(),
          capacity: int.tryParse(_capacityController.text.trim()),
          isActive: _isActive,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث المجموعة'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('تعديل المجموعة'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم المجموعة'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'الحد الأقصى للاعبين (اختياري)'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('نشطة'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('حفظ التعديلات'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
