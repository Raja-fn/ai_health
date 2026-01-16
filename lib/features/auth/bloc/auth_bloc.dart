import 'package:bloc/bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SupabaseClient supabase;
  late final StreamSubscription _authStateSubscription;

  AuthBloc({required this.supabase}) : super(AuthInitial()) {
    // Listen to Supabase auth changes immediately
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;

      if (event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.tokenRefreshed) {
        // Check status whenever an auth event occurs
        add(AuthCheckStatus());
      }
    });

    on<AuthCheckStatus>(_onAuthCheckStatus);
    on<AuthSignOut>(_onAuthSignOut);
    on<AuthLoginWithEmail>(_onAuthLoginWithEmail);
    on<AuthSignUpWithEmail>(_onAuthSignUpWithEmail);

    // Manually add initial check to establish current status
    add(AuthCheckStatus());
  }

  Future<void> _onAuthCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final Session? session = supabase.auth.currentSession;
      final User? user = session?.user;

      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError("Failed to check session status: $e"));
    }
  }

  Future<void> _onAuthLoginWithEmail(
    AuthLoginWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await supabase.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );

      if (response.user != null) {
        emit(AuthAuthenticated(response.user));
      } else {
        emit(const AuthError("Login failed"));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError("Login error: $e"));
    }
  }

  Future<void> _onAuthSignUpWithEmail(
    AuthSignUpWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await supabase.auth.signUp(
        email: event.email,
        password: event.password,
      );

      if (response.user != null) {
        emit(AuthAuthenticated(response.user));
      } else {
        emit(const AuthError("Sign up failed"));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError("Sign up error: $e"));
    }
  }

  Future<void> _onAuthSignOut(
    AuthSignOut event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await supabase.auth.signOut();
      // signOut will trigger onAuthStateChange, which will call AuthCheckStatus,
      // but we emit Unauthenticated immediately for responsiveness.
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    return super.close();
  }
}
