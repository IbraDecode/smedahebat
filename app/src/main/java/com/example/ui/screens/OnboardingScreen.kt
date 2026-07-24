package com.example.ui.screens

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.Orientation
import androidx.compose.foundation.gestures.draggable
import androidx.compose.foundation.gestures.rememberDraggableState
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.School
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

@Composable
fun OnboardingScreen(onSwipeComplete: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .systemBarsPadding(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier
                .widthIn(max = 480.dp)
                .fillMaxHeight()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.weight(1f))
            
            Icon(
                imageVector = Icons.Filled.School,
                contentDescription = "Graduation Cap",
                modifier = Modifier.size(120.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            
            Spacer(modifier = Modifier.height(32.dp))
            
            Text(
                text = "Welcome to Smeda Hebat",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onBackground
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Text(
                text = "Your digital school companion",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Spacer(modifier = Modifier.weight(1.5f))
            
            SwipeToUnlockButton(onSwipeComplete = onSwipeComplete)
            
            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}

@Composable
fun SwipeToUnlockButton(onSwipeComplete: () -> Unit) {
    val coroutineScope = rememberCoroutineScope()
    var width by remember { mutableIntStateOf(0) }
    val thumbSize = 64.dp
    val thumbSizePx = with(LocalDensity.current) { thumbSize.toPx() }
    val dragOffset = remember { Animatable(0f) }
    
    val infiniteTransition = rememberInfiniteTransition()
    val pulseAlpha by infiniteTransition.animateFloat(
        initialValue = 0.4f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(800),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulseAlpha"
    )
    
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(thumbSize)
            .clip(CircleShape)
            .background(MaterialTheme.colorScheme.primaryContainer)
            .onSizeChanged { width = it.width },
        contentAlignment = Alignment.CenterStart
    ) {
        Row(
            modifier = Modifier.align(Alignment.Center).padding(start = 24.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Swipe Right",
                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f),
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.width(8.dp))
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = pulseAlpha),
                modifier = Modifier.size(20.dp)
            )
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = pulseAlpha * 0.7f),
                modifier = Modifier.size(20.dp).offset(x = (-8).dp)
            )
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = pulseAlpha * 0.4f),
                modifier = Modifier.size(20.dp).offset(x = (-16).dp)
            )
        }
        
        Box(
            modifier = Modifier
                .offset { IntOffset(dragOffset.value.roundToInt(), 0) }
                .size(thumbSize)
                .padding(4.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.primary)
                .draggable(
                    orientation = Orientation.Horizontal,
                    state = rememberDraggableState { delta ->
                        val newValue = dragOffset.value + delta
                        val maxScroll = (width - thumbSizePx).coerceAtLeast(0f)
                        coroutineScope.launch {
                            dragOffset.snapTo(newValue.coerceIn(0f, maxScroll))
                        }
                    },
                    onDragStopped = {
                        val maxScroll = (width - thumbSizePx).coerceAtLeast(0f)
                        if (dragOffset.value > maxScroll * 0.8f) {
                            coroutineScope.launch {
                                dragOffset.animateTo(maxScroll)
                                onSwipeComplete()
                            }
                        } else {
                            coroutineScope.launch {
                                dragOffset.animateTo(0f)
                            }
                        }
                    }
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = "Swipe Forward",
                tint = MaterialTheme.colorScheme.onPrimary,
                modifier = Modifier.size(28.dp)
            )
        }
    }
}
