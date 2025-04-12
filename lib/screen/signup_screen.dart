import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:chewata/utils/constants/sizes.dart';
import 'package:chewata/utils/constants/text_strings.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSize.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo and Title
              const SizedBox(height: TSize.spaceBtwSections * 4),
              Center(
                child: Image.asset(
                  'assets/logos/chewata_logo.png',
                  height: 80,
                ),
              ),
              const SizedBox(height: TSize.spaceBtwSections),
              Text(TText.signupTitle, 
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: TSize.spaceBtwItems),
              Text(TText.signupSubTitle, 
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              
              // Form
              const SizedBox(height: TSize.spaceBtwSections),
              Form(
                child: Column(
                  children: [
                    // Full Name
                    TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Iconsax.user),
                        labelText: TText.fullName,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(TSize.inputFieldRadius),
                        ),
                      ),
                    ),
                    const SizedBox(height: TSize.spaceBtwInputFields),
                    
                    // Username
                    TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Iconsax.user_edit),
                        labelText: TText.username,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(TSize.inputFieldRadius),
                        ),
                      ),
                    ),
                    const SizedBox(height: TSize.spaceBtwInputFields),
                    
                    // Age
                    TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Iconsax.calendar),
                        labelText: TText.age,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(TSize.inputFieldRadius),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: TSize.spaceBtwInputFields),
                    
                    // Phone Number
                    TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Iconsax.call),
                        labelText: TText.phoneNo,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(TSize.inputFieldRadius),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: TSize.spaceBtwInputFields),
                    
                    // Password
                    TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Iconsax.password_check),
                        labelText: TText.password,
                        suffixIcon: const Icon(Iconsax.eye_slash),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(TSize.inputFieldRadius),
                        ),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: TSize.spaceBtwInputFields),
                    
                    // Terms & Conditions
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(value: true, onChanged: (value) {}),
                        ),
                        const SizedBox(width: TSize.spaceBtwItems),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${TText.iAgreeTo} ',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              TextSpan(
                                text: TText.privacyPolicy,
                                style: Theme.of(context).textTheme.bodyMedium!.apply(
                                  color: Theme.of(context).primaryColor,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Theme.of(context).primaryColor,
                                ),
                              ),
                              TextSpan(
                                text: ' ${TText.and} ',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              TextSpan(
                                text: TText.termsOfUse,
                                style: Theme.of(context).textTheme.bodyMedium!.apply(
                                  color: Theme.of(context).primaryColor,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: TSize.spaceBtwSections),
                    
                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: TSize.buttonHeight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(TSize.buttonRadius),
                          ),
                        ),
                        child: const Text(TText.createAccount),
                      ),
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
} 