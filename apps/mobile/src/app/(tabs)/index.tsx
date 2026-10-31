import { BIO_MAX } from '@riff-lab/core';
import { Text } from 'react-native';

import { PlaceholderScreen } from '../../components/PlaceholderScreen';

export default function Feed() {
  return (
    <PlaceholderScreen message="Looks will show up here.">
      {/* Proves shared packages bundle through Metro. Goes away with the first real screen. */}
      <Text>Bio limit from @riff-lab/core: {BIO_MAX}</Text>
    </PlaceholderScreen>
  );
}
