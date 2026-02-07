import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/user_follow_provider.dart';

/// Reusable Follow/Unfollow button component
class FollowButton extends StatefulWidget {
  final int targetUserId;
  final bool? initialIsFollowing;
  final VoidCallback? onFollowChanged;
  final double? width;
  final double? height;
  final double? fontSize;
  final Color? followColor;
  final Color? unfollowColor;
  final Color? textColor;

  const FollowButton({
    super.key,
    required this.targetUserId,
    this.initialIsFollowing,
    this.onFollowChanged,
    this.width,
    this.height,
    this.fontSize,
    this.followColor,
    this.unfollowColor,
    this.textColor,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool? _localIsFollowing;
  bool _isLoading = false;
  DateTime? _lastActionTime; // Track last action time to prevent rapid clicks
  static const Duration _cooldownPeriod = Duration(seconds: 2); // Cooldown after error

  @override
  void initState() {
    super.initState();
    _localIsFollowing = widget.initialIsFollowing;
    
    // Check follow status if not provided
    if (_localIsFollowing == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkFollowStatus();
      });
    }
  }

  @override
  void didUpdateWidget(FollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIsFollowing != oldWidget.initialIsFollowing) {
      _localIsFollowing = widget.initialIsFollowing;
    }
  }

  void _checkFollowStatus() {
    final followProvider = Provider.of<UserFollowProvider>(context, listen: false);
    final isFollowing = followProvider.isFollowing(widget.targetUserId);
    if (mounted) {
      setState(() {
        _localIsFollowing = isFollowing;
      });
    }
  }

  Future<void> _handleFollowToggle() async {
    // ✅ Prevent rapid clicks
    if (_isLoading) {
      print('⚠️ [FollowButton] Already processing, ignoring click');
      return;
    }
    
    // ✅ Check cooldown period after error
    if (_lastActionTime != null) {
      final timeSinceLastAction = DateTime.now().difference(_lastActionTime!);
      if (timeSinceLastAction < _cooldownPeriod) {
        final remainingSeconds = (_cooldownPeriod - timeSinceLastAction).inSeconds;
        print('⚠️ [FollowButton] Cooldown active, please wait ${remainingSeconds}s');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please wait $remainingSeconds second${remainingSeconds > 1 ? 's' : ''} before trying again'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _lastActionTime = DateTime.now();
    });

    final followProvider = Provider.of<UserFollowProvider>(context, listen: false);
    final currentStatus = _localIsFollowing ?? false;

    try {
      print('🔘 [FollowButton] Toggling follow status for user: ${widget.targetUserId}');
      print('🔘 [FollowButton] Current status: ${currentStatus ? "Following" : "Not Following"}');
      
      // Clear any previous errors
      followProvider.clearError();
      
      if (currentStatus) {
        await followProvider.unfollowUser(widget.targetUserId);
      } else {
        await followProvider.followUser(widget.targetUserId);
      }

      // ✅ Wait for server response with timeout (max 5 seconds)
      bool responseReceived = false;
      int maxWaitTime = 5000; // 5 seconds
      int checkInterval = 200; // Check every 200ms
      int waited = 0;
      
      while (!responseReceived && waited < maxWaitTime) {
        await Future.delayed(Duration(milliseconds: checkInterval));
        waited += checkInterval;
        
        // Check if we got a response (error or status changed)
        if (followProvider.error != null && followProvider.error!.isNotEmpty) {
          responseReceived = true;
          print('❌ [FollowButton] Provider error received: ${followProvider.error}');
        } else {
          // Check if follow status changed (indicates success)
          final newStatus = followProvider.isFollowing(widget.targetUserId);
          if (newStatus != currentStatus) {
            responseReceived = true;
            print('✅ [FollowButton] Follow status changed - response received');
          }
        }
      }
      
      // ✅ Handle timeout or response
      if (!responseReceived && waited >= maxWaitTime) {
        print('⚠️ [FollowButton] Timeout waiting for server response');
        // Assume success if no error (optimistic update already applied)
        if (followProvider.error == null || followProvider.error!.isEmpty) {
          print('✅ [FollowButton] No error, assuming success');
          responseReceived = true;
        }
      }
      
      // Check for errors from provider
      if (followProvider.error != null && followProvider.error!.isNotEmpty) {
        print('❌ [FollowButton] Provider error: ${followProvider.error}');
        
        // Revert optimistic update on error
        if (mounted) {
          setState(() {
            _localIsFollowing = currentStatus; // Revert to previous state
            _isLoading = false;
            _lastActionTime = DateTime.now(); // Set cooldown on error
          });
          
          // Error message is already user-friendly from provider
          String errorMessage = followProvider.error!;
          
          // ✅ Show error with retry option, but respect cooldown
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  // ✅ Wait for cooldown before retrying
                  Future.delayed(_cooldownPeriod, () {
                    if (mounted) {
                      _handleFollowToggle();
                    }
                  });
                },
              ),
            ),
          );
        }
        return;
      }

      // Update local state
      if (mounted) {
        setState(() {
          _localIsFollowing = !currentStatus;
          _isLoading = false;
        });
        print('✅ [FollowButton] Follow status updated successfully');
      }

      // Callback
      widget.onFollowChanged?.call();
    } catch (e, stackTrace) {
      print('❌ [FollowButton] Exception: $e');
      print('📍 Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to follow status changes
    return Consumer<UserFollowProvider>(
      builder: (context, followProvider, child) {
        // Update local state from provider if available
        final providerStatus = followProvider.isFollowing(widget.targetUserId);
        if (_localIsFollowing == null || providerStatus != _localIsFollowing) {
          _localIsFollowing = providerStatus;
        }

        final isFollowing = _localIsFollowing ?? false;
        // ✅ Use only local loading state - don't use provider's global isLoading
        // This prevents all buttons from showing loading when one button is clicked
        final isLoading = _isLoading;

        return SizedBox(
          width: widget.width ?? 100,
          height: widget.height ?? 36,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleFollowToggle,
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing
                  ? (widget.unfollowColor ?? Colors.grey.shade300)
                  : (widget.followColor ?? Colors.blue),
              foregroundColor: widget.textColor ?? (isFollowing ? Colors.black87 : Colors.white),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.textColor ?? (isFollowing ? Colors.black87 : Colors.white),
                      ),
                    ),
                  )
                : Text(
                    isFollowing ? 'Unfollow' : 'Follow',
                    style: TextStyle(
                      fontSize: widget.fontSize ?? 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

