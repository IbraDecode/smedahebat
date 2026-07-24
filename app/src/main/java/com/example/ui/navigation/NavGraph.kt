package com.example.ui.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.ui.screens.DashboardScreen
import com.example.ui.screens.LoginScreen
import com.example.ui.screens.OnboardingScreen
import com.example.ui.screens.SetupScreen

@Composable
fun AppNavGraph(
    navController: NavHostController = rememberNavController()
) {
    NavHost(navController = navController, startDestination = "onboarding") {
        composable("onboarding") {
            OnboardingScreen(
                onSwipeComplete = {
                    navController.navigate("login") {
                        popUpTo("onboarding") { inclusive = true }
                    }
                }
            )
        }
        composable("login") {
            LoginScreen(
                onLoginSuccess = {
                    navController.navigate("setup") {
                        popUpTo("login") { inclusive = true }
                    }
                }
            )
        }
        composable("setup") {
            SetupScreen(
                onSetupComplete = {
                    navController.navigate("dashboard") {
                        popUpTo("setup") { inclusive = true }
                    }
                }
            )
        }
        composable("dashboard") {
            DashboardScreen()
        }
    }
}
