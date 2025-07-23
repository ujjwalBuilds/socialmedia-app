import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socialmedia/api_service/user_provider.dart';

class CustomDropdown extends StatefulWidget {
  final Function(bool isAnonymous)? onSelectionChanged;
  const CustomDropdown({super.key, this.onSelectionChanged});

  @override
  CustomDropdownState createState() => CustomDropdownState();
}

class CustomDropdownState extends State<CustomDropdown> {
  bool isAnonymous = false;
  bool isExpanded = false;
  late UserProviderall userProvider;

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProviderall>(context, listen: false);
  }

  void _toggleDropdown() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  void _selectOption(bool anonymous) {
    setState(() {
      isAnonymous = anonymous;
      isExpanded = false;
    });
    if (widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(anonymous);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _toggleDropdown,
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: isExpanded 
                  ? const BorderRadius.vertical(top: Radius.circular(8))
                  : BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  isAnonymous 
                    ? Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.question_mark,
                          size: 20,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      )
                    : CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(userProvider.profilePic!),
                      ),
                  const SizedBox(width: 8),
                  
                  Text(
                    isAnonymous ? 'Anonymous' : userProvider.userName ?? 'User',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: isDarkMode ? Colors.white : Colors.black,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.black : Colors.white,
                  borderRadius:  BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _selectOption(false),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: NetworkImage(userProvider.profilePic!),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Post as ${userProvider.userName}',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    InkWell(
                      onTap: () => _selectOption(true),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.question_mark,
                                size: 20,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Post Anonymously',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
