#
#  server.py
#  这是一个更新后的 Python Flask 服务器，用于接收视频、分析并返回集锦区间。
#  请确保您已安装 Flask 和 moviepy: `pip install Flask moviepy`
#

import os
import random
import tempfile
from flask import Flask, jsonify, request
#from moviepy.editor import VideoFileClip
from moviepy import VideoFileClip


app = Flask(__name__)

@app.route('/upload_video', methods=['POST'])
def upload_video():
    """
    Handles video upload, processes the video to get frame count,
    generates random highlight intervals, and returns them as JSON.
    """
    print("Received a request to upload video.")

    # Check if a video file is in the request
    if 'video' not in request.files:
        return jsonify({'error': 'No video file provided'}), 400

    video_file = request.files['video']

    # Save the video to a temporary file
    temp_dir = tempfile.gettempdir()
    temp_path = os.path.join(temp_dir, video_file.filename or 'temp_video.mp4')
    video_file.save(temp_path)
    print(f"Video saved to temporary path: {temp_path}")

    try:
        # Load video clip and get its duration in seconds
        clip = VideoFileClip(temp_path)
        duration_in_seconds = clip.duration

        # Assume a standard frame rate of 30 fps to calculate total frames.
        # This is a simplification; a more robust solution would read the video's actual fps.
        fps = 30
        total_frames = int(duration_in_seconds * fps)
        print(f"Video duration: {duration_in_seconds:.2f}s, Total frames: {total_frames}")

        if total_frames < 300: # Ensure video is long enough for 3 highlights
            return jsonify({'error': 'Video is too short to generate highlights.'}), 400

        highlights = []
        for _ in range(3):
            # Generate random start and end frames for 30-60 frames intervals
            # Ensures start frame is not too close to the end
            start_frame = random.randint(1, total_frames - 60)
            end_frame = start_frame + random.randint(30, 60)

            # Clamp the end frame to the total frames
            if end_frame > total_frames:
                end_frame = total_frames

            highlights.append({'startFrame': start_frame, 'endFrame': end_frame})

        response = {'highlights': highlights}
        return jsonify(response)

    except Exception as e:
        print(f"An error occurred: {e}")
        return jsonify({'error': 'Failed to process video.'}), 500

    finally:
        # Clean up the temporary file
        if os.path.exists(temp_path):
            os.remove(temp_path)
            print("Temporary video file removed.")

if __name__ == '__main__':
    # 0.0.0.0 allows the server to be accessible from other devices on the same network
    app.run(host='0.0.0.0', port=5001, debug=True)

