import { Link } from 'expo-router';

import { PlaceholderScreen } from '../components/PlaceholderScreen';

export default function NotFound() {
  return (
    <PlaceholderScreen message="Page not found">
      <Link href="/" replace>
        Go to Feed
      </Link>
    </PlaceholderScreen>
  );
}
