import 'package:Rusic/managers/server_manager/supabase_manager.dart';
import 'package:Rusic/managers/credentials_manager.dart'; // Fix: Added missing import
import 'package:flutter/material.dart';

void supabaseConfigurationScreenState(BuildContext context) {
  final formKey = GlobalKey<FormState>();
  final credentialsManager =
      CredentialsManager(); // Fix: Defined the credentials manager instance
  TextEditingController urlController = TextEditingController();
  TextEditingController apiKeyController = TextEditingController();
  TextEditingController tableNameController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Dialog(
            backgroundColor: const Color.fromRGBO(36, 33, 33, 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: SizedBox(
              width: constraints.maxWidth > 700
                  ? constraints.maxWidth * 0.6
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Supabase Configuration",
                        style: TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 16),
                      const Text("Enter Table Name"),
                      TextFormField(
                        controller: tableNameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter Valid Table Name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text("Enter URL"),
                      TextFormField(
                        controller: urlController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter Valid URL';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text("Enter Anon-API Key"),
                      TextFormField(
                        controller: apiKeyController,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter Valid Anon-API Key';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: FilledButton(
                            onPressed: () async {
                              if (formKey.currentState?.validate() ?? false) {
                                // Verify connection before saving
                                final connection = SupabaseConnection(
                                  supabaseUrl: urlController.text.trim(),
                                  supabaseAnonKey: apiKeyController.text.trim(),
                                  tableName: tableNameController.text.trim(),
                                );

                                final isConnected = await connection
                                    .isConnected();

                                // Fix: Ensure widget is still mounted after async call
                                if (!dialogContext.mounted) return;

                                if (isConnected) {
                                  await credentialsManager
                                      .addSupabaseConfiguration({
                                        'url': urlController.text.trim(),
                                        'apiKey': apiKeyController.text.trim(),
                                        'tableName': tableNameController.text
                                            .trim(),
                                      });

                                  // Fix: Check again after second async call
                                  if (!dialogContext.mounted) return;
                                  Navigator.pop(dialogContext);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Supabase connected and saved successfully!',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Failed to connect to Supabase. Check your credentials.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ButtonStyle(
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            child: const Text("Save"),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
