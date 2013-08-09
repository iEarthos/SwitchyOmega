part of switchy_browser;

/*!
 * Copyright (C) 2012-2013, The SwitchyOmega Authors. Please see the AUTHORS file
 * for details.
 *
 * This file is part of SwitchyOmega.
 *
 * SwitchyOmega is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * SwitchyOmega is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with SwitchyOmega.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * Handles communication with the browser and other browser related stuff.
 */
abstract class Browser {
  Future applyProfile(Profile profile);

  /**
   * Set an repeating alarm which fires every [periodInMinutes].
   * Replaces a previously set alarm with the same [name].
   * A non-positive value of [periodInMinutes] clears the alarm.
   * Note: Cancelling the [StreamSubscription] also clears the alarm.
   */
  Stream<String> setAlarm(String name, num periodInMinutes);

  /**
   * Fetch the content of [url]. Throws [DownloadFailException] on failure.
   */
  Future<String> download(String url);
}

class DownloadFailException implements Exception {
  final status;
  final error;

  DownloadFailException(this.status, this.error);
}
