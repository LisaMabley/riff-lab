import { Ionicons } from '@expo/vector-icons';
import { Tabs } from 'expo-router';
import type { BottomTabNavigationOptions } from 'expo-router/tabs';
import type { ComponentProps } from 'react';

type IconProps = ComponentProps<typeof Ionicons>;
type IconName = IconProps['name'];
type TabBarIcon = NonNullable<BottomTabNavigationOptions['tabBarIcon']>;

function tabIcon(active: IconName, inactive: IconName): TabBarIcon {
  return function TabIcon({ focused, color, size }) {
    // ColorValue also allows null and numbers, but the tab bar only passes its tint colors.
    const iconColor = color as IconProps['color'];
    return <Ionicons name={focused ? active : inactive} color={iconColor} size={size} />;
  };
}

// VoiceOver labels come from `title` ("Feed, tab, 1 of 3"). Setting tabBarAccessibilityLabel would
// replace that whole string and drop the tab's position.
export default function TabsLayout() {
  return (
    <Tabs>
      <Tabs.Screen
        name="index"
        options={{ title: 'Feed', tabBarIcon: tabIcon('home', 'home-outline') }}
      />
      <Tabs.Screen
        name="new-post"
        options={{ title: 'New post', tabBarIcon: tabIcon('add-circle', 'add-circle-outline') }}
      />
      <Tabs.Screen
        name="profile"
        options={{ title: 'Profile', tabBarIcon: tabIcon('person', 'person-outline') }}
      />
    </Tabs>
  );
}
