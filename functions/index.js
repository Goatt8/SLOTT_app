const admin = require("firebase-admin");
const crypto = require("node:crypto");
const fs = require("node:fs/promises");
const os = require("node:os");
const path = require("node:path");
const { spawn } = require("node:child_process");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const ffmpegPath = require("@ffmpeg-installer/ffmpeg").path;

const STORAGE_BUCKET =
  process.env.FIREBASE_STORAGE_BUCKET || "bababam-935c8.firebasestorage.app";

admin.initializeApp({
  storageBucket: STORAGE_BUCKET,
});

const db = admin.firestore();
const bucket = admin.storage().bucket(STORAGE_BUCKET);

const REGION = "asia-northeast3";
const RENDER_WIDTH = 1080;
const RENDER_HEIGHT = 1920;
const PAGE_DURATION_SECONDS = 3;
const FONT_DIR = path.join(__dirname, "assets", "fonts");

const FONT_PRESETS = {
  doHyeon: {
    family: "Do Hyeon",
    file: "DoHyeon-Regular.ttf",
    format: "truetype",
    postScale: 1,
    hourScale: 1,
  },
  blacHanSans: {
    family: "Black Han Sans",
    file: "BlackHanSans-Regular.ttf",
    format: "truetype",
    postScale: 1,
    hourScale: 1,
  },
  bagelfatOne: {
    family: "Bagel Fat One",
    file: "BagelFatOne-Regular.ttf",
    format: "truetype",
    postScale: 1,
    hourScale: 1,
  },
  nanumPenScript: {
    family: "Nanum Pen Script",
    file: "NanumPenScript-Regular.ttf",
    format: "truetype",
    postScale: 1.22,
    hourScale: 1,
  },
  silkscreen: {
    family: "Silkscreen",
    file: "Silkscreen-Regular.ttf",
    format: "truetype",
    postScale: 0.78,
    hourScale: 1,
  },
  blackOpsOne: {
    family: "Black Ops One",
    file: "BlackOpsOne-Regular.ttf",
    format: "truetype",
    postScale: 1,
    hourScale: 1,
  },
  "noto serif kr": {
    family: "Noto Serif KR",
    file: "NotoSerifKR-Regular.otf",
    format: "opentype",
    postScale: 1,
    hourScale: 1,
  },
  gowunBatang: {
    family: "Gowun Batang",
    file: "GowunBatang-Regular.ttf",
    format: "truetype",
    postScale: 1,
    hourScale: 1,
  },
  fredoka: {
    family: "Fredoka",
    file: "Fredoka-Regular.ttf",
    format: "truetype",
    postScale: 1,
    hourScale: 1,
  },
  PressStart2P: {
    family: "Press Start 2P",
    file: "PressStart2P-Regular.ttf",
    format: "truetype",
    postScale: 1,
    hourScale: 0.82,
  },
  orbitron: {
    family: "Orbitron",
    file: "Orbitron-Regular.ttf",
    format: "truetype",
    postScale: 1,
    hourScale: 1,
  },
  playfairDisplay: {
    family: "Playfair Display",
    file: "PlayfairDisplay-Regular.ttf",
    format: "truetype",
    postScale: 1,
    hourScale: 1,
  },
  cinzel: {
    family: "Cinzel",
    file: "Cinzel-Regular.ttf",
    format: "truetype",
    postScale: 1,
    hourScale: 1,
  },
};

exports.mergeGroupVideos = onDocumentCreated(
  {
    document: "daily_export_jobs/{jobId}",
    region: REGION,
    timeoutSeconds: 540,
    memory: "2GiB",
    cpu: 1,
  },
  async (event) => {
    const jobId = event.params.jobId;
    const jobRef = event.data.ref;
    const job = event.data.data();

    if (!job || job.status !== "pending") return;

    const workDir = await fs.mkdtemp(path.join(os.tmpdir(), "slott-export-"));

    try {
      await jobRef.update({
        status: "processing",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const result = await buildDailyVideo({ jobId, job, workDir });

      await jobRef.update({
        status: "completed",
        resultUrl: result.url,
        resultStoragePath: result.storagePath,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      console.error("Daily export failed", jobId, error);
      await jobRef.update({
        status: "failed",
        errorMessage: String(error && error.message ? error.message : error),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } finally {
      await fs.rm(workDir, { recursive: true, force: true }).catch(() => {});
    }
  }
);

async function buildDailyVideo({ jobId, job, workDir }) {
  const { groupId, requestedBy, dayKey, useDiceLayout } = job;
  if (!groupId || !requestedBy || !dayKey) {
    throw new Error("Invalid export job");
  }

  const [groupSnap, requesterSnap] = await Promise.all([
    db.collection("group").doc(groupId).get(),
    db.collection("user").doc(requestedBy).get(),
  ]);
  if (!groupSnap.exists) throw new Error(`Group not found: ${groupId}`);

  const group = { id: groupSnap.id, ...groupSnap.data() };
  const requester = requesterSnap.exists ? requesterSnap.data() : {};
  const blockedUserIds = new Set(requester.blockedUserIds || []);

  const postsSnap = await db
    .collection("group")
    .doc(groupId)
    .collection("posts")
    .where("dayKey", "==", dayKey)
    .get();

  const posts = postsSnap.docs
    .map((doc) => ({ id: doc.id, ...doc.data() }))
    .filter((post) => !blockedUserIds.has(post.authorId));

  const hours = [...new Set(posts.map((post) => Number(post.hourSlot)))]
    .filter((hour) => Number.isInteger(hour))
    .sort((a, b) => a - b);
  if (hours.length === 0) throw new Error("No posts for export");

  const slotOwnerIds = effectiveSlotOwnerIds(group);
  const memberIds = [...new Set(slotOwnerIds.filter(Boolean))];
  const userSnaps = await Promise.all(
    memberIds.map((userId) => db.collection("user").doc(userId).get())
  );
  const usersById = Object.fromEntries(
    userSnaps
      .filter((snap) => snap.exists)
      .map((snap) => [snap.id, { id: snap.id, ...snap.data() }])
  );

  const viewerStyle = {
    fontId: requester.fontId || "doHyeon",
    colorId: requester.colorId || "white",
    hourFontId: requester.hourFontId || "doHyeon",
  };
  const preset = layoutPreset({
    memberCount: slotOwnerIds.length,
    useDiceLayout: Boolean(useDiceLayout),
  });
  const slotRects = buildSlotRects(slotOwnerIds.length, preset);

  const pagePaths = [];
  for (const hour of hours) {
    const pagePath = path.join(workDir, `hour_${String(hour).padStart(2, "0")}.mp4`);
      const slots = await buildSlots({
        hour,
        posts,
        slotOwnerIds,
        usersById,
      slotRects,
        workDir,
      });

    await renderHourVideo({
      pagePath,
      slots,
      hour,
      viewerStyle,
      workDir,
    });
    pagePaths.push(pagePath);
  }

  const outputPath = path.join(workDir, `${jobId}.mp4`);
  if (pagePaths.length === 1) {
    await fs.copyFile(pagePaths[0], outputPath);
  } else {
    await concatVideos({ pagePaths, outputPath, workDir });
  }

  const storagePath = `merged_videos/${groupId}/${dayKey}_${jobId}.mp4`;
  const token = crypto.randomUUID();
  await bucket.upload(outputPath, {
    destination: storagePath,
    metadata: {
      contentType: "video/mp4",
      metadata: {
        firebaseStorageDownloadTokens: token,
      },
    },
  });

  return {
    storagePath,
    url:
      `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/` +
      `${encodeURIComponent(storagePath)}?alt=media&token=${token}`,
  };
}

function effectiveSlotOwnerIds(group) {
  const memberIds = Array.isArray(group.memberIds) ? group.memberIds : [];
  const rawSlotOwnerIds = Array.isArray(group.slotOwnerIds)
    ? group.slotOwnerIds
    : [];
  const memberCount = Number(group.memberCount || memberIds.length || rawSlotOwnerIds.length);
  const slotCount = Math.max(memberCount, memberIds.length, rawSlotOwnerIds.length);

  return Array.from({ length: slotCount }, (_, index) => {
    if (rawSlotOwnerIds[index]) return rawSlotOwnerIds[index];
    if (memberIds[index]) return memberIds[index];
    return null;
  });
}

function layoutPreset({ memberCount, useDiceLayout }) {
  const supportsVertical = [2, 3, 4, 5, 6].includes(memberCount);
  const supportsDice = [3, 4, 6, 7, 8, 9, 10].includes(memberCount);
  const forceDice = [7, 8, 9, 10].includes(memberCount);
  const willUseDice =
    forceDice || (useDiceLayout && supportsDice) || (!supportsVertical && supportsDice);

  if (!willUseDice) {
    return {
      useGrid: false,
      columns: 1,
      fixedSlotCount: null,
      cardRadius: 24,
      cardOuterMargin: 1,
      gridHorizontalPadding: 2,
      gridVerticalPadding: 2,
      gridSpacing: 2,
    };
  }

  let columns = 3;
  let fixedSlotCount = 12;
  if (memberCount === 3) {
    columns = 3;
    fixedSlotCount = 3;
  } else if (memberCount === 4) {
    columns = 2;
    fixedSlotCount = 4;
  } else if (memberCount === 6) {
    columns = 2;
    fixedSlotCount = 6;
  } else if (memberCount === 7 || memberCount === 8) {
    columns = 2;
    fixedSlotCount = 8;
  } else if (memberCount === 9) {
    columns = 3;
    fixedSlotCount = 9;
  }

  return {
    useGrid: true,
    columns,
    fixedSlotCount,
    cardRadius: 16,
    cardOuterMargin: 0,
    gridHorizontalPadding: 2,
    gridVerticalPadding: 2,
    gridSpacing: 2,
  };
}

function buildSlotRects(slotCount, preset) {
  const scale = RENDER_WIDTH / 390;

  if (!preset.useGrid) {
    const margin = preset.cardOuterMargin * scale;
    const slotHeight = RENDER_HEIGHT / slotCount;
    return Array.from({ length: slotCount }, (_, index) => ({
      x: margin,
      y: slotHeight * index + margin,
      w: RENDER_WIDTH - margin * 2,
      h: slotHeight - margin * 2,
    }));
  }

  const gridSlotCount = preset.fixedSlotCount || slotCount;
  const rows = Math.ceil(gridSlotCount / preset.columns);
  const horizontalPadding = preset.gridHorizontalPadding * scale;
  const verticalPadding = preset.gridVerticalPadding * scale;
  const spacing = preset.gridSpacing * scale;
  const width =
    (RENDER_WIDTH - horizontalPadding * 2 - spacing * (preset.columns - 1)) /
    preset.columns;
  const height =
    (RENDER_HEIGHT - verticalPadding * 2 - spacing * (rows - 1)) / rows;

  return Array.from({ length: slotCount }, (_, index) => {
    const row = Math.floor(index / preset.columns);
    const column = index % preset.columns;
    return {
      x: horizontalPadding + column * (width + spacing),
      y: verticalPadding + row * (height + spacing),
      w: width,
      h: height,
    };
  });
}

async function buildSlots({ hour, posts, slotOwnerIds, usersById, slotRects, workDir }) {
  const ownerSlotCounts = slotOwnerIds.reduce((acc, ownerId) => {
    if (ownerId) acc[ownerId] = (acc[ownerId] || 0) + 1;
    return acc;
  }, {});

  const slots = [];
  for (let slotIndex = 0; slotIndex < slotRects.length; slotIndex += 1) {
    const ownerId = slotOwnerIds[slotIndex] || null;
    const user = ownerId ? usersById[ownerId] || null : null;
    const post = findPostForSlot({
      posts,
      hour,
      slotIndex,
      ownerId,
      allowLegacyFallback: Boolean(ownerId && ownerSlotCounts[ownerId] === 1),
    });
    let videoPath = null;
    if (post && post.videoUrl) {
      videoPath = await downloadToFile({
        url: post.videoUrl,
        outputPath: path.join(workDir, `slot_${hour}_${slotIndex}_${post.id}.mp4`),
      });
    }

    slots.push({
      slotIndex,
      rect: slotRects[slotIndex],
      ownerId,
      user,
      post,
      videoPath,
    });
  }
  return slots;
}

function findPostForSlot({ posts, hour, slotIndex, ownerId, allowLegacyFallback }) {
  const exact = latestPost(
    posts.filter(
      (post) => Number(post.hourSlot) === hour && Number(post.slotIndex) === slotIndex
    )
  );
  if (exact || !allowLegacyFallback || !ownerId) return exact;

  return latestPost(
    posts.filter(
      (post) =>
        Number(post.hourSlot) === hour &&
        Number(post.slotIndex) === -1 &&
        post.authorId === ownerId
    )
  );
}

function latestPost(posts) {
  return posts.sort((a, b) => timestampMillis(b.createdAt) - timestampMillis(a.createdAt))[0] || null;
}

function timestampMillis(value) {
  if (!value) return 0;
  if (typeof value.toMillis === "function") return value.toMillis();
  if (value._seconds) return value._seconds * 1000;
  return 0;
}

async function downloadToFile({ url, outputPath }) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Failed to download media: ${response.status} ${url}`);
  }
  const buffer = Buffer.from(await response.arrayBuffer());
  await fs.writeFile(outputPath, buffer);
  return outputPath;
}

function fontPreset(fontId) {
  return FONT_PRESETS[fontId] || FONT_PRESETS.doHyeon;
}

async function renderHourVideo({ pagePath, slots, hour, viewerStyle, workDir }) {
  const videoSlots = slots.filter((slot) => slot.videoPath);
  const args = ["-y"];
  for (const slot of videoSlots) {
    args.push("-i", slot.videoPath);
  }

  const filterParts = [
    `color=c=black:s=${RENDER_WIDTH}x${RENDER_HEIGHT}:d=${PAGE_DURATION_SECONDS}[base]`,
  ];
  let current = "base";
  videoSlots.forEach((slot, index) => {
    const label = `v${index}`;
    const next = `tmp${index}`;
    const rect = roundRect(slot.rect);
    filterParts.push(
      `[${index}:v]scale=${rect.w}:${rect.h}:force_original_aspect_ratio=increase,crop=${rect.w}:${rect.h},setsar=1[${label}]`
    );
    filterParts.push(
      `[${current}][${label}]overlay=${rect.x}:${rect.y}:shortest=0[${next}]`
    );
    current = next;
  });

  const textFilterResult = await appendTextFilters({
    filterParts,
    inputLabel: current,
    slots,
    hour,
    viewerStyle,
    workDir,
  });

  args.push(
    "-filter_complex",
    filterParts.join(";"),
    "-map",
    `[${textFilterResult}]`,
    "-t",
    String(PAGE_DURATION_SECONDS),
    "-r",
    "30",
    "-an",
    "-c:v",
    "libx264",
    "-pix_fmt",
    "yuv420p",
    "-movflags",
    "+faststart",
    pagePath
  );

  await runFfmpeg(args);
}

function roundRect(rect) {
  return {
    x: Math.round(rect.x),
    y: Math.round(rect.y),
    w: Math.round(rect.w),
    h: Math.round(rect.h),
  };
}

async function appendTextFilters({
  filterParts,
  inputLabel,
  slots,
  hour,
  viewerStyle,
  workDir,
}) {
  const hourFont = fontPreset(viewerStyle.hourFontId || "doHyeon");
  const postFont = fontPreset(viewerStyle.fontId || "doHyeon");
  const hourFontFile = path.join(FONT_DIR, hourFont.file);
  const postFontFile = path.join(FONT_DIR, postFont.file);
  const hourFontSize = Math.round(88 * hourFont.hourScale);
  const postFontSize = Math.round(55 * postFont.postScale);
  const sleepFontSize = 52;
  const commentColor = colorForDrawText(viewerStyle.colorId);
  let current = inputLabel;
  let index = 0;

  for (const slot of slots) {
    const rect = roundRect(slot.rect);
    const hasVideo = Boolean(slot.post && slot.videoPath);
    const hasOwner = Boolean(slot.user);
    if (!hasOwner) continue;

    const hourTextPath = path.join(
      workDir,
      `text_${hour}_${slot.slotIndex}_hour.txt`
    );
    await fs.writeFile(hourTextPath, `${hour}:00`, "utf8");

    const hourY = Math.round(rect.y + rect.h / 2 - hourFontSize * 0.95);
    const hourColor = hasVideo ? "white@0.96" : "white@0.10";
    const nextHourLabel = `text${index++}`;
    filterParts.push(
      `[${current}]${drawTextFilter({
        fontFile: hourFontFile,
        textFile: hourTextPath,
        fontSize: hourFontSize,
        color: hourColor,
        x: `${rect.x}+(${rect.w}-text_w)/2`,
        y: String(hourY),
      })}[${nextHourLabel}]`
    );
    current = nextHourLabel;

    const comment = hasVideo ? String(slot.post.comment || "").trim() : "";
    const text = comment || (!hasVideo ? "Zzz" : "");
    if (!text) continue;

    const textPath = path.join(
      workDir,
      `text_${hour}_${slot.slotIndex}_comment.txt`
    );
    await fs.writeFile(textPath, text, "utf8");

    const textY = Math.round(rect.y + rect.h / 2 + 16);
    const nextCommentLabel = `text${index++}`;
    filterParts.push(
      `[${current}]${drawTextFilter({
        fontFile: postFontFile,
        textFile: textPath,
        fontSize: comment ? postFontSize : sleepFontSize,
        color: comment ? commentColor : "0x1E78DC@0.78",
        x: `${rect.x}+(${rect.w}-text_w)/2`,
        y: String(textY),
      })}[${nextCommentLabel}]`
    );
    current = nextCommentLabel;
  }

  return current;
}

function drawTextFilter({ fontFile, textFile, fontSize, color, x, y }) {
  const options = [
    fontFile ? `fontfile=${escapeFilterValue(fontFile)}` : null,
    `textfile=${escapeFilterValue(textFile)}`,
    `fontsize=${fontSize}`,
    `fontcolor=${color}`,
    `x=${x}`,
    `y=${y}`,
  ].filter(Boolean);

  return `drawtext=${options.join(":")}`;
}

function escapeFilterValue(value) {
  return String(value)
    .replaceAll("\\", "\\\\")
    .replaceAll(":", "\\:")
    .replaceAll("'", "\\'");
}

function colorForDrawText(colorId) {
  const colors = {
    white: "white",
    black: "black",
    grey: "0x8E8E93",
    red: "0xFF3B30",
    mint: "0x48D6A2",
    pink: "0xFFB3C7",
    sunset: "0xFFA142",
    blue: "0xB667FF",
    green: "0x36D893",
    "mid Night": "0xC13383",
  };
  return colors[colorId] || "white";
}

async function concatVideos({ pagePaths, outputPath, workDir }) {
  const listPath = path.join(workDir, "concat.txt");
  const lines = pagePaths
    .map((pagePath) => `file '${pagePath.replaceAll("'", "'\\''")}'`)
    .join("\n");
  await fs.writeFile(listPath, lines);

  await runFfmpeg([
    "-y",
    "-f",
    "concat",
    "-safe",
    "0",
    "-i",
    listPath,
    "-c",
    "copy",
    outputPath,
  ]);
}

function runFfmpeg(args) {
  return new Promise((resolve, reject) => {
    const child = spawn(ffmpegPath, args);
    let stderr = "";
    child.stderr.on("data", (data) => {
      stderr += data.toString();
    });
    child.on("error", reject);
    child.on("close", (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`ffmpeg exited with ${code}: ${stderr}`));
      }
    });
  });
}
