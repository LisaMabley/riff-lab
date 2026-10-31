import { BIO_MAX } from '@riff-lab/core';
import { StatusBar } from 'expo-status-bar';
import { StyleSheet, Text, View } from 'react-native';

export default function Home() {
  return (
    <View style={styles.container}>
      <Text>Riff Lab</Text>
      {/* Proves shared packages bundle through Metro. Goes away with the first real screen. */}
      <Text>Bio limit from @riff-lab/core: {BIO_MAX}</Text>
      <StatusBar style="auto" />
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
