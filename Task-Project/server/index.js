require('dotenv').config();
const express = require('express');
const {
  S3Client,
  GetObjectCommand,
  PutObjectCommand,
  ListObjectsV2Command,
} = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const cors = require('cors');
const path = require('path');
const { PassThrough } = require('stream'); // ✅ Required for stream piping

const app = express();
const port = process.env.PORT || 3001;

const s3Client = new S3Client({ region: 'us-east-1' });
const BUCKET_NAME = 'photo-gallery-images-unique-name-123456789-new';

app.use(cors());
app.use(express.json());


// ✅✅ INSERT THIS BLOCK RIGHT HERE
app.get('/api/proxy-image/:key', async (req, res) => {
  const key = `uploads/${req.params.key}`;

  const command = new GetObjectCommand({
    Bucket: BUCKET_NAME,
    Key: key,
  });

  try {
    const s3Response = await s3Client.send(command);

    res.setHeader('Content-Type', s3Response.ContentType || 'application/octet-stream');
    res.setHeader('Content-Length', s3Response.ContentLength);

    const stream = s3Response.Body;
    stream.pipe(res);
  } catch (err) {
    console.error('Error streaming image from S3:', err);
    res.status(404).send('Image not found.');
  }
});
// ✅✅ END INSERT BLOCK


// ✅ Presigned PUT URL for upload
app.get('/api/generate-upload-url', async (req, res) => {
  const { fileName, fileType } = req.query;
  if (!fileName || !fileType) {
    return res.status(400).send('fileName and fileType query parameters are required.');
  }

  const key = `uploads/${Date.now()}_${fileName}`;
  const command = new PutObjectCommand({
    Bucket: BUCKET_NAME,
    Key: key,
    ContentType: fileType,
  });

  try {
    const signedUrl = await getSignedUrl(s3Client, command, { expiresIn: 300 }); // 5 min
    res.json({ uploadUrl: signedUrl, key });
  } catch (error) {
    console.error('Error generating pre-signed URL', error);
    res.status(500).send('Could not generate upload URL.');
  }
});

// ✅ Presigned GET URL for a single image
app.get('/api/generate-view-url', async (req, res) => {
  const { key } = req.query;
  if (!key) return res.status(400).send('Missing key');

  try {
    const command = new GetObjectCommand({ Bucket: BUCKET_NAME, Key: key });
    const signedUrl = await getSignedUrl(s3Client, command, { expiresIn: 600 }); // 10 min
    res.json({ viewUrl: signedUrl });
  } catch (error) {
    console.error('Error generating view URL', error);
    res.status(500).send('Could not generate view URL.');
  }
});

// ✅ List all uploaded image URLs
app.get('/api/images', async (req, res) => {
  const command = new ListObjectsV2Command({
    Bucket: BUCKET_NAME,
    Prefix: 'uploads/',
  });

  try {
    const { Contents = [] } = await s3Client.send(command);
    const imageKeys = Contents.map(item => item.Key);

    // Return proxy URLs instead of presigned S3 URLs
    const imageUrls = imageKeys.map(key => {
      const shortKey = key.replace('uploads/', '');
      return `${req.protocol}://${req.get('host')}/api/proxy-image/${shortKey}`;
    });

    res.json(imageUrls.reverse());
  } catch (error) {
    console.error('Error listing images', error);
    res.status(500).send('Could not list images.');
  }
});


app.listen(port, () => {
  console.log(`Server running on port ${port}`);
  console.log(`S3 Bucket: ${BUCKET_NAME}`);
});
