import 'package:flutter/material.dart';
import 'package:Rusic/managers/credentials_manager.dart';

void serverConfigurationScreenState(BuildContext context) {
  TextEditingController serverNameController = TextEditingController();
  TextEditingController serverAddressController = TextEditingController();
  final serverFormKey = GlobalKey<FormState>();
  final credentialsManager = CredentialsManager();
  showDialog(
    context: context,
    builder: (BuildContext builder) {
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
                  key: serverFormKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Server Configuration",
                        style: TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 16),
                      const Text("Server Name"),
                      TextFormField(
                        controller: serverNameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter Valid Server Name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text("Server Address"),
                      TextFormField(
                        controller: serverAddressController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter Valid Server Address';
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
                              if (serverFormKey.currentState?.validate() ??
                                  false) {
                                await credentialsManager
                                    .addServerConfiguration({
                                      'serverAddress': serverAddressController
                                          .text
                                          .trim(),
                                      'serverName': serverNameController.text
                                          .trim(),
                                    });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Server configuration saved successfully!',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
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
