import type { ReactNode } from 'react';
import { StyleSheet, Text, View } from 'react-native';

type Props = {
  message: string;
  children?: ReactNode;
};

export function PlaceholderScreen({ message, children }: Props) {
  return (
    <View style={styles.container}>
      <Text>{message}</Text>
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },
});
